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
  cluster_name = "jcloud-stage-eks-abcde"
  partition    = data.aws_partition.current.partition
  vpc_name     = "jcloud-vpc-stage-abcde"
}

################################################################################
# k8s Module
################################################################################

module "jcloud" {
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
  source = "../../"

  region       = "us-east-1"
  cluster_name = local.cluster_name
  app_ref      = local.cluster_name
  vpc_name     = local.vpc_name
  eks_version  = "1.28"

  cidr            = "10.200.0.0/20"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.200.6.0/24", "10.200.7.0/24", "10.200.8.0/24"]
  private_subnets = ["10.200.0.0/23", "10.200.2.0/23", "10.200.4.0/23"]

  kms_key_owners = [data.aws_caller_identity.current.arn]

  eks_admin_users = [data.aws_caller_identity.current.arn]

  shared_gpu_instance_type = ["g5.xlarge"]
  gpu_instance_type        = ["g5.xlarge"]
  standard_instance_type   = ["t3a.medium", "t3a.small"]
  system_instance_type     = ["t3a.medium"]


  shared_gpu_node_labels = { "k8s.amazonaws.com/accelerator" = "nvidia-tesla-t4" }
  gpu_node_labels        = { "k8s.amazonaws.com/accelerator" = "nvidia-tesla-t4" }

  enable_monitor_store = true
  enable_monitor = true
  enable_prometheus = true
  enable_metrics = true
  enable_tracing = false
  enable_otlp_collector = true
  enable_thanos = false
  enable_cert_manager = true
  enable_kong         = true
  enable_linkerd      = true
  enable_karpenter    = true
  enable_ebs          = false
  enable_gpu          = true
  enable_knative      = true
  enable_external_dns = true
  certs = [
    {
      domain = "wolf.jina.ai",
      region = "us-east-1",
      zone_id = "Z03454213POOFEWAVPRB6",
      tls_secret_name = "wolf-tls",
      issuer_email = "issuer@wolf.jina.ai"
    },
    {
      domain = "dev.jina.ai",
      region = "us-east-1",
      zone_id = "Z0864958UDWVOFSW5J11",
      tls_secret_name = "dev-tls",
      issuer_email = "issuer@wolf.jina.ai"
    },
    {
      domain = "dev.wolf.jina.ai",
      region = "us-east-1",
      zone_id = "Z096347533MF5145X5J4B",
      tls_secret_name = "dev-wolf-tls",
      issuer_email = "issuer@wolf.jina.ai"
    },
  ]

  tags = {
    Terraform                = "true"
    "karpenter.sh/discovery" = "${local.cluster_name}"
  }
}
