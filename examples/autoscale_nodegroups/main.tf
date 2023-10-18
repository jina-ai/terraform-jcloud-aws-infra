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
  cluster_name = "mycluster"
  partition    = data.aws_partition.current.partition
  vpc_name     = "medium-vpc-for-dev"
  gpu_types = {
    "P2" : "nvidia-tesla-k80",
    "P3" : "nvidia-tesla-v100",
    "G4" : "nvidia-tesla-t4",
    "P4" : "nvidia-tesla-a100",
    "G5" : "nvidia-a10g"
  }
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

  cidr            = "10.200.0.0/18"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  public_subnets  = ["10.200.60.0/24", "10.200.61.0/24", "10.200.62.0/24"]
  private_subnets = ["10.200.0.0/22", "10.200.4.0/22", "10.200.8.0/22", "10.200.12.0/22"]

  shared_gpu_instance_type = ["g4dn.xlarge"]

  aws_auth_node_iam_role_arns_non_windows = ["autoscale-eks-node-group"] // Add node group arn to cluster

  kms_key_owners = [data.aws_caller_identity.current.arn]

  eks_admin_users = [data.aws_caller_identity.current.arn, "NikosPitsillos"]

  enable_cert_manager       = false
  enable_kong               = true
  enable_linkerd            = true
  enable_cluster_autoscaler = true
  enable_karpenter          = false
  enable_gpu                = true

  tags = {
    Terraform                = "true"
    "karpenter.sh/discovery" = "${local.cluster_name}"
  }
}

################################################################################
# EKS Managed Node Group
################################################################################

module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name            = "autoscale"
  use_name_prefix = false
  platform        = "linux"

  iam_role_use_name_prefix = false

  create = true

  cluster_name        = local.cluster_name
  cluster_endpoint    = module.jcloud.cluster_endpoint
  cluster_auth_base64 = base64decode(module.jcloud.cluster_certificate_authority_data)
  cluster_version     = "1.27"

  instance_types = ["g4dn.xlarge"]

  min_size     = 0
  max_size     = 10
  desired_size = 1

  subnet_ids                        = module.jcloud.private_subnets
  vpc_security_group_ids            = [module.jcloud.node_security_group_id]
  cluster_primary_security_group_id = module.jcloud.cluster_primary_security_group_id

  ami_type            = "AL2_x86_64_GPU"
  ami_release_version = "1.27.5-20231002"

  update_launch_template_default_version = true

  block_device_mappings = {
    device_name = "/dev/xvda"
    ebs = {
      volume_size           = 120
      delete_on_termination = true
    }
  }

  network_interfaces = [
    {
      device_index       = 0
      network_card_index = 0
    },
  ]

  tag_specifications = ["instance", "volume", "network-interface"]

  bootstrap_extra_args = "--system-reserved cpu=300m,memory=0.5Gi,ephemeral-storage=1Gi --eviction-hard memory.available<200Mi,nodefs.available<10% --image-gc-high-threshold=80 --image-gc-low-threshold=60"

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  tags = merge({
    "jina.ai/node-type" = "asg"
    "jina.ai/gpu-type"  = "nvidia"
  }, var.tags)

  taints = {
    gpu = {
      key    = "nvidia.com/gpu"
      effect = "NO_SCHEDULE"
    }
  }

  labels = {
    "jina.ai/node-type"             = "asg"
    "jina.ai/gpu-type"              = "nvidia"
    "k8s.amazonaws.com/accelerator" = local.gpu_types.G4
  }
}
