
data "aws_eks_cluster" "ml-cluster" {
  name = var.eks_cluster_name
  lifecycle {
    ignore_changes = ["*"]
  }
}





################################################################################
# EFS configuration
################################################################################


resource "aws_efs_file_system" "eks_efs" {
  creation_token = "${var.eks_cluster_name}-efs"
  encrypted      = true

  tags = {
    Name = "${var.eks_cluster_name}-efs"
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "${var.eks_cluster_name}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all local traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.eks_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.eks_cluster_name}-efs-sg"
  }
}

resource "aws_efs_mount_target" "eks_efs_mount_targets" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.eks_efs.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_access_point" "eks_efs_access_point" {
  file_system_id = aws_efs_file_system.eks_efs.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name = "${var.eks_cluster_name}-efs-access-point"
  }
}


data "aws_vpc" "eks_vpc" {
  id = var.vpc_id
}

################################################################################
# EBS CSI DRIVER
################################################################################

module "ebs_csi_driver_irsa" {
 source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
 role_name             = "${var.eks_cluster_name}-ebs-csi-driver"
 role_policy_arns = {
   policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
 }
 oidc_providers = {
  main = {
     provider_arn               = data.aws_eks_cluster.ml-cluster.arn
     namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
  }
 }
 tags = {
    Name = "${var.eks_cluster_name}-ebs-csi-driver"
  }
}

resource "kubernetes_storage_class" "ebs-gp3-sc" {
  metadata {
    name = "gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
}
