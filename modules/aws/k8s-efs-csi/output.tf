output "efs_arn" {
  description = "Amazon Resource Name of the file system"
  value       = try(aws_efs_file_system.eks_efs[0].arn, "")
}

output "efs_id" {
  description = " The ID that identifies the file system (e.g., fs-ccfc0d65)."
  value       = try(aws_efs_file_system.eks_efs[0].id, "")
}

output "efs_dns_name" {
  description = "The DNS name for the filesystem"
  value       = try(aws_efs_file_system.eks_efs[0].dns_name, "")
}

output "mount_target_dns_name" {
  description = "The DNS name for the given subnet/AZ"
  value       = try(aws_efs_mount_target.eks_efs_mount_target[0].mount_target_dns_name, "")
}

output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = module.efs_csi_irsa.iam_role_arn
}

output "iam_role_name" {
  description = "Name of IAM role"
  value       = module.efs_csi_irsa.iam_role_name
}
