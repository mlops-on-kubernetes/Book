################################################################################
# Section 1
################################################################################
terraform {
  required_version = ">= 1.3.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 5.83"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
  }
}

provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

data "aws_availability_zones" "available" {}

locals {
  name   = "mlops-cluster"
  region = "us-west-2"
  cluster_version = "1.31"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    EKSCluster  = local.name
  }
}

################################################################################
# VPC Configuration
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  cluster_addons = {
    aws-efs-csi-driver     = {
      service_account_role_arn = module.efs_csi_driver_irsa.iam_role_arn 
    }
  }

  enable_efa_support = true
  enable_irsa = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}


################################################################################
# EBS Storage Class
################################################################################

resource "kubernetes_storage_class" "ebs-gp3-sc" {
  metadata {
    name        = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.eks.amazonaws.com"
  reclaim_policy      = "Delete"
}

################################################################################
# EFS configuration
################################################################################
module "efs_csi_driver_irsa" {
 source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
 role_name             = "${local.name}-efs-csi-driver"
 role_policy_arns = {
   policy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
 }
 oidc_providers = {
  main = {
     provider_arn               = module.eks.oidc_provider_arn
     namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
  }
 }
 tags = local.tags
}

resource "kubernetes_annotations" "efs-service-account-annotation" {
  api_version = "v1"
  kind        = "ServiceAccount"

   metadata {
     name      = "efs-csi-controller-sa"
     namespace = "kube-system"
   }

  annotations = {
   "eks.amazonaws.com/role-arn" = module.efs_csi_driver_irsa.iam_role_arn
  }
}

resource "aws_efs_file_system" "efs-share" {
  creation_token = "ml-share"
  encrypted      = true
  tags = {
    Name = "ml-share"
  }
}

resource "aws_efs_access_point" "efs-ap" {
  file_system_id = aws_efs_file_system.efs-share.id
  
  posix_user {
    gid = 100
    uid = 1000
  }

  root_directory {

    creation_info {
      owner_uid   = 1000
      owner_gid   = 100
      permissions = "0777"
    }
    path = "/shared"
  }
}

resource "aws_efs_mount_target" "efs-share" {
  file_system_id  = aws_efs_file_system.efs-share.id
  for_each        = toset(module.vpc.private_subnets)
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name        = "${local.name}-efs"
  description = "Allow inbound NFS traffic from private subnets of the VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow NFS 2049/tcp"
    cidr_blocks = [local.vpc_cidr]
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
  }

  tags = local.tags
}

resource "kubernetes_storage_class" "efs" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Retain"
  parameters = {
   #fileSystemId     = aws_efs_file_system.efs-share.id
   #directoryPerms   = "700"
  }
}

resource "kubernetes_namespace" "jupyter" {
  metadata {
    name = "jupyter"
  }
}

resource "kubernetes_persistent_volume_claim" "efs-pvc" {
  metadata {
    name = "efs-claim"
    namespace = "jupyter"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    #volume_name = "${kubernetes_persistent_volume.example.metadata.0.name}"
    storage_class_name = "efs-sc"
  }
}

resource "kubernetes_persistent_volume" "jupter-efs-pv" {
  metadata {
    name = "efs-pv"
  }
  spec {
    storage_class_name = "efs-sc"
    capacity = {
      storage = "5Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = format("%s::%s", aws_efs_file_system.efs-share.id, aws_efs_access_point.efs-ap.id)
        read_only     = false
      }
    }
  }
}

