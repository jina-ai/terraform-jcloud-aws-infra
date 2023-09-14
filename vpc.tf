module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.vpc_name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_vpn_gateway = false

  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.vpc_name}-default" }

  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.vpc_name}-default" }

  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.vpc_name}-default" }

  enable_dns_support = true

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
    "jina.ai/tier"                                = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.cluster_name
    "jina.ai/tier"           = "private"
  }

  tags = var.tags
}

################################################################################
# VPC peering
# enable it when you need to communicate with other VPC
################################################################################

# resource "aws_vpc_peering_connection" "eks-peering" {
#   peer_owner_id = data.aws_caller_identity.current.account_id
#   peer_vpc_id   = module.vpc.vpc_id
#   vpc_id        = data.terraform_remote_state.vpc.outputs.vpc_id
#   auto_accept   = true

#   accepter {
#     allow_remote_vpc_dns_resolution = true
#   }

#   requester {
#     allow_remote_vpc_dns_resolution = true
#   }
# }

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 3.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc_endpoint_security_group.security_group_id]

  endpoints = {
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    }
  }

  tags = var.tags
}

module "vpc_endpoint_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = join("-", compact(["${local.vpc_name}-k8s-endpoints"]))
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.cidr]
  ingress_rules       = ["https-443-tcp"]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["https-443-tcp"]

  tags = var.tags
}
