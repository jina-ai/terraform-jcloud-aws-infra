output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = try(module.external_dns_irsa.iam_role_arn, var.remote_role)
}

output "iam_role_name" {
  description = "Name of IAM role"
  value       = try(module.external_dns_irsa.iam_role_name, var.remote_role)
}
