data "aws_region" "current" {}

locals {
  image_lookup = {
    "af-south-1"     = "877085696533.dkr.ecr.af-south-1.amazonaws.com/"
    "ap-east-1"      = "800184023465.dkr.ecr.ap-east-1.amazonaws.com/"
    "ap-northeast-1" = "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com/"
    "ap-northeast-2" = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/"
    "ap-northeast-3" = "602401143452.dkr.ecr.ap-northeast-3.amazonaws.com/"
    "ap-south-1"     = "602401143452.dkr.ecr.ap-south-1.amazonaws.com/"
    "ap-southeast-1" = "602401143452.dkr.ecr.ap-southeast-1.amazonaws.com/"
    "ap-southeast-2" = "602401143452.dkr.ecr.ap-southeast-2.amazonaws.com/"
    "ca-central-1"   = "602401143452.dkr.ecr.ca-central-1.amazonaws.com/"
    "cn-north-1"     = "918309763551.dkr.ecr.cn-north-1.amazonaws.com.cn/"
    "cn-northwest-1" = "961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn/"
    "eu-central-1"   = "602401143452.dkr.ecr.eu-central-1.amazonaws.com/"
    "eu-north-1"     = "602401143452.dkr.ecr.eu-north-1.amazonaws.com/"
    "eu-south-1"     = "590381155156.dkr.ecr.eu-south-1.amazonaws.com/"
    "eu-west-1"      = "602401143452.dkr.ecr.eu-west-1.amazonaws.com/"
    "eu-west-2"      = "602401143452.dkr.ecr.eu-west-2.amazonaws.com/"
    "eu-west-3"      = "602401143452.dkr.ecr.eu-west-3.amazonaws.com/"
    "me-south-1"     = "558608220178.dkr.ecr.me-south-1.amazonaws.com/"
    "sa-east-1"      = "602401143452.dkr.ecr.sa-east-1.amazonaws.com/"
    "us-east-1"      = "602401143452.dkr.ecr.us-east-1.amazonaws.com/"
    "us-east-2"      = "602401143452.dkr.ecr.us-east-2.amazonaws.com/"
    "us-gov-east-1"  = "151742754352.dkr.ecr.us-gov-east-1.amazonaws.com/"
    "us-gov-west-1"  = "013241004608.dkr.ecr.us-gov-west-1.amazonaws.com/"
    "us-west-1"      = "602401143452.dkr.ecr.us-west-1.amazonaws.com/"
    "us-west-2"      = "602401143452.dkr.ecr.us-west-2.amazonaws.com/"
  }
}

resource "aws_efs_file_system" "eks_efs" {
  count          = var.create_efs ? 1 : 0
  creation_token = "efs-${var.cluster_name}"
  tags           = var.tags
}

module "vpc_efs_security_group" {
  count   = var.create_efs ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.cluster_name}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = [var.allow_cidr]
  ingress_rules       = ["nfs-tcp"]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-tcp", "all-udp"]

  tags = var.tags
}

resource "aws_efs_mount_target" "eks_efs_mount_target" {
  count           = var.create_efs && length(var.subnets) > 0 ? length(var.subnets) : 0
  file_system_id  = join("", aws_efs_file_system.eks_efs.*.id)
  subnet_id       = var.subnets[count.index]
  security_groups = module.vpc_efs_security_group.*.security_group_id
}

resource "helm_release" "efs-csi" {
  namespace        = var.namespace
  create_namespace = true

  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  version    = "2.2.7"

  set {
    name  = "image.repository"
    value = join("", [lookup(local.image_lookup, var.region, local.image_lookup["us-east-1"]), "eks/aws-efs-csi-driver"])
  }

  set {
    name  = "controller.serviceAccount.create"
    value = true
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.efs_csi_irsa.iam_role_arn
    type  = "string"
  }

  set {
    name  = "controller.nodeSelector.jina\\.ai/node-type"
    value = "system"
    type  = "string"
  }

  depends_on = [
    module.efs_csi_irsa
  ]
}

module "efs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name             = "AmazonEKS_EFS_CSI_DriverRole_${var.cluster_name}"
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
}

resource "kubectl_manifest" "efs_sc" {
  count     = var.create_efs ? 1 : 0
  yaml_body = <<-YAML
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: efs-storageclass
  provisioner: efs.csi.aws.com
  volumeBindingMode: ${var.binding_mode}
  reclaimPolicy: Delete
  allowVolumeExpansion: true
  parameters:
    fileSystemId: ${aws_efs_file_system.eks_efs[0].id}
    provisioningMode: efs-ap
  YAML
}
