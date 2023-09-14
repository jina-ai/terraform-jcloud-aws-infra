output "kubecost_metric_buckets" {
  description = "Metrics bucket for kubecost"
  value       = try(aws_s3_bucket.metrics[0].id, "")
}

output "kubecost_role" {
  description = "Kubecost IAM role name"
  value       = aws_iam_role.kubecost_role.name
}

output "kubecost_user_arn" {
  description = "Kubecost IAM user arn"
  value       = module.iam_user.iam_user_arn
}
