output "region" {
  description = "Region of the AWS Resources"
  value       = var.region
}

################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.jcloud.cluster_arn
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.jcloud.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.jcloud.cluster_endpoint
  sensitive   = true
}

output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.jcloud.cluster_id
  sensitive   = true
}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.jcloud.cluster_name
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.jcloud.cluster_oidc_issuer_url
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.jcloud.cluster_version
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = module.jcloud.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.jcloud.cluster_status
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = module.jcloud.cluster_primary_security_group_id
}

################################################################################
# Cluster Security Group
################################################################################

output "cluster_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the cluster security group"
  value       = module.jcloud.cluster_security_group_arn
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = module.jcloud.cluster_security_group_id
}

################################################################################
# Node Security Group
################################################################################

output "node_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the node shared security group"
  value       = module.jcloud.node_security_group_arn
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.jcloud.node_security_group_id
}

################################################################################
# IRSA
################################################################################

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = module.jcloud.oidc_provider
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = module.jcloud.oidc_provider_arn
}

################################################################################
# IAM Role
################################################################################

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = module.jcloud.cluster_iam_role_name
  sensitive   = true
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.jcloud.cluster_iam_role_arn
}

output "cluster_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = module.jcloud.cluster_iam_role_unique_id
  sensitive   = true
}

################################################################################
# EKS Addons
################################################################################

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = module.jcloud.cluster_addons
}

################################################################################
# EKS Identity Provider
################################################################################

output "cluster_identity_providers" {
  description = "Map of attribute maps for all EKS identity providers enabled"
  value       = module.jcloud.cluster_identity_providers
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group created"
  value       = module.jcloud.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "Arn of cloudwatch log group created"
  value       = module.jcloud.cloudwatch_log_group_arn
}

################################################################################
# Additional
################################################################################

output "efs_irsa_arn" {
  description = "efs service account IAM Role ARN"
  value       = module.jcloud.efs_irsa_arn
}

output "cert_manager_irsa_arn" {
  description = " cert manager service account IAM Role ARN"
  value       = module.jcloud.cert_manager_irsa_arn
}

output "efs_id" {
  description = " The ID that identifies the file system (e.g., fs-ccfc0d65)."
  value       = module.jcloud.efs_id
}

output "efs_dns_name" {
  description = "The DNS name for the filesystem"
  value       = module.jcloud.efs_dns_name
  sensitive   = true
}

output "mount_target_dns_name" {
  description = "The DNS name for the given subnet/AZ"
  value       = module.jcloud.mount_target_dns_name
}

output "monitor_iam_user_name" {
  description = "The user's name"
  value       = module.jcloud.monitor_iam_user_name
  sensitive   = true
}

output "monitor_iam_user_arn" {
  description = "The ARN assigned by AWS for this user"
  value       = module.jcloud.monitor_iam_user_arn
  sensitive   = true
}

output "monitor_iam_access_key_id" {
  description = "The access key ID"
  value       = module.jcloud.monitor_iam_access_key_id
  sensitive   = true
}

output "monitor_iam_access_key_secret" {
  description = "The access key secret"
  value       = module.jcloud.monitor_iam_access_key_secret
  sensitive   = true
}

output "monitor_iam_role_arn" {
  description = "ARN of IAM role"
  value       = module.jcloud.monitor_iam_role_arn
}

output "monitor_iam_role_name" {
  description = "Name of IAM role"
  value       = module.jcloud.monitor_iam_role_name
}

################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.jcloud.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.jcloud.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.jcloud.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.jcloud.private_subnets
  sensitive   = true
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.jcloud.private_subnet_arns
  sensitive   = true
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.jcloud.public_subnets
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.jcloud.public_subnet_arns
}

output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = module.jcloud.azs
  sensitive   = true
}


