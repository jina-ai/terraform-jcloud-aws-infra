output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = module.aws_load_balancer_controller_irsa.iam_role_arn
}

output "iam_role_name" {
  description = "Name of IAM role"
  value       = module.aws_load_balancer_controller_irsa.iam_role_name
}
