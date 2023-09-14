output "iam_user_name" {
  description = "The user's name"
  value       = module.iam_user.iam_user_name
}

output "iam_user_arn" {
  description = "The ARN assigned by AWS for this user"
  value       = module.iam_user.iam_user_arn
}

output "iam_access_key_id" {
  description = "The access key ID"
  value       = module.iam_user.iam_access_key_id
}

output "iam_access_key_secret" {
  description = "The access key secret"
  value       = module.iam_user.iam_access_key_secret
  sensitive   = true
}

output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = module.iam_assumable_role_monitor.iam_role_arn
}

output "iam_role_name" {
  description = "Name of IAM role"
  value       = module.iam_assumable_role_monitor.iam_role_name
}
