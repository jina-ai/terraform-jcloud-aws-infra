data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name       = local.cluster_name
  depends_on = [module.jcloud]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = local.cluster_name
  depends_on = [module.jcloud]
}

locals {
  cluster_name = "monitor-cluster"
  partition    = data.aws_partition.current.partition
  vpc_name     = "vpc-monitoring"
}

################################################################################
# k8s Module
################################################################################

module "jcloud" {
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
  source = "../../"

  region       = "us-east-1"
  cluster_name = local.cluster_name

  vpc_name    = local.vpc_name
  eks_version = "1.27"

  cidr            = "10.200.0.0/20"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.200.6.0/24", "10.200.7.0/24", "10.200.8.0/24"]
  private_subnets = ["10.200.0.0/23", "10.200.2.0/23", "10.200.4.0/23"]

  kms_key_owners = [data.aws_caller_identity.current.arn]

  eks_admin_users = [data.aws_caller_identity.current.arn]

  enable_cert_manager = true
  enable_kong         = true
  enable_linkerd      = true
  enable_ebs          = true
  enable_karpenter    = true

  enable_monitor       = true
  enable_metrics       = true
  enable_logging       = true
  enable_tracing       = true
  enable_monitor_store = true

  tags = {
    Terraform = "true"
    "karpenter.sh/discovery" = "${local.cluster_name}"
  }
}
