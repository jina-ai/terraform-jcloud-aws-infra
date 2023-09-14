################################################################################
# Cluster
################################################################################

output "cluster_name" {
  description = "The name of the cluster"
  value       = local.cluster_name
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.eks.cluster_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.eks.cluster_status
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = module.eks.cluster_primary_security_group_id
}

################################################################################
# Cluster Security Group
################################################################################

output "cluster_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the cluster security group"
  value       = module.eks.cluster_security_group_arn
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = module.eks.cluster_security_group_id
}

################################################################################
# Node Security Group
################################################################################

output "node_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the node shared security group"
  value       = module.eks.node_security_group_arn
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

################################################################################
# IRSA
################################################################################

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = module.eks.oidc_provider_arn
}

################################################################################
# IAM Role
################################################################################

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = module.eks.cluster_iam_role_unique_id
}

################################################################################
# EKS Addons
################################################################################

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = module.eks.cluster_addons
}

################################################################################
# EKS Identity Provider
################################################################################

output "cluster_identity_providers" {
  description = "Map of attribute maps for all EKS identity providers enabled"
  value       = module.eks.cluster_identity_providers
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group created"
  value       = module.eks.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "Arn of cloudwatch log group created"
  value       = module.eks.cloudwatch_log_group_arn
}

################################################################################
# Additional
################################################################################

# TODO: Might be just the efs csi
output "region" {
  description = "Region of the AWS resources"
  value       = var.region
}

output "aws_auth_configmap_yaml" {
  description = "[DEPRECATED - use `var.manage_aws_auth_configmap`] Formatted yaml output for base aws-auth configmap containing roles used in cluster node groups/fargate profiles"
  value       = module.eks.aws_auth_configmap_yaml
}

output "cert_manager_irsa_arn" {
  description = " cert manager service account IAM Role ARN"
  value       = try(module.cert_manager[0].iam_role_arn, "")
}

output "monitor_iam_user_name" {
  description = "The user's name"
  value       = try(module.monitor[0].iam_user_name, "")
}

output "monitor_iam_user_arn" {
  description = "The ARN assigned by AWS for this user"
  value       = try(module.monitor[0].iam_user_arn, "")
}

output "monitor_iam_access_key_id" {
  description = "The access key ID"
  value       = try(module.monitor[0].iam_access_key_id, "")
}

output "monitor_iam_access_key_secret" {
  description = "The access key secret"
  value       = try(module.monitor[0].iam_access_key_secret, "")
  sensitive   = true
}

output "monitor_iam_role_arn" {
  description = "ARN of IAM role"
  value       = try(module.monitor[0].iam_role_arn, "")
}

output "monitor_iam_role_name" {
  description = "Name of IAM role"
  value       = try(module.monitor[0].iam_role_name, "")
}


################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.vpc.private_subnet_arns
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.vpc.public_subnet_arns
}

output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = var.azs
}

################################################################################
# EFS CSI
################################################################################

output "efs_irsa_arn" {
  description = "efs service account IAM Role ARN"
  value       = try(module.eks-efs-csi.efs_arn, "")
}

output "efs_id" {
  description = " The ID that identifies the file system (e.g., fs-ccfc0d65)."
  value       = try(module.eks-efs-csi[0].efs_id, "")
}

output "efs_dns_name" {
  description = "The DNS name for the filesystem"
  value       = try(module.eks-efs-csi[0].efs_dns_name, "")
}

output "mount_target_dns_name" {
  description = "The DNS name for the given subnet/AZ"
  value       = try(module.eks-efs-csi[0].mount_target_dns_name, "")
}
