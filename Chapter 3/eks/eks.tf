################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.10"

  cluster_name    = local.name
  cluster_version = "1.29"

  # Give the Terraform identity admin access to the cluster
  # which will allow it to deploy resources into the cluster
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-ebs-csi-driver     = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn 
    }
    aws-efs-csi-driver     = {
      service_account_role_arn = module.efs_csi_driver_irsa.iam_role_arn 
    }
  }

  enable_efa_support = true
  enable_irsa = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    static_ng = {
      use_custom_launch_template = false
      launch_template_name       = "" 
      instance_types             = ["m5.large"]

      min_size     = 2
      max_size     = 3
      desired_size = 2
      disk_size    = 50
      
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }
      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
    }
  }

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.oidc_provider_arn}"
}

################################################################################
# EBS Configuration
################################################################################

module "ebs_csi_driver_irsa" {
 source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
 role_name             = "${local.name}-ebs-csi-driver"
 role_policy_arns = {
   policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
 }
 oidc_providers = {
  main = {
     provider_arn               = module.eks.oidc_provider_arn
     namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
  }
 }
 tags = local.tags
}

resource "kubernetes_storage_class" "ebs-gp3-sc" {
  metadata {
    name = "gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"
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

################################################################################
# Controller & Node IAM roles, SQS Queue, Eventbridge Rules
################################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.9"

  cluster_name = module.eks.cluster_name

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = local.name
  create_pod_identity_association = true

  tags = local.tags
}

################################################################################
# Helm charts
################################################################################

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  #repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "0.36.2"
  wait                = false

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}
