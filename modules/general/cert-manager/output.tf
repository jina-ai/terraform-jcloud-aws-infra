output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = try(module.cert_manager_irsa.iam_role_arn, var.remote_cert_manager_role)
}

output "iam_role_name" {
  description = "Name of IAM role"
  value       = try(module.cert_manager_irsa.iam_role_name, var.remote_cert_manager_role)
}
