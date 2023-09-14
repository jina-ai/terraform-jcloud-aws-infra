data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  metrics_bucket = length(var.metrics_bucket) > 0 ? var.metrics_bucket : "${var.cluster_name}-metrics"
  log_bucket     = length(var.log_bucket) > 0 ? var.log_bucket : "${var.cluster_name}-logs"
  traces_bucket  = length(var.traces_bucket) > 0 ? var.traces_bucket : "${var.cluster_name}-traces"
}

module "iam_user" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  name          = "${var.cluster_name}-monitor-user"
  force_destroy = true

  password_reset_required = false

  tags = var.tags
}

module "iam_policy_s3" {
  count  = var.create_buckets ? 1 : 0
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${var.cluster_name}-s3-policy"
  path        = "/"
  description = "Manage monitor bucket"

  tags = var.tags

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "Statement",
          "Effect": "Allow",
          "Action": [
              "s3:ListBucket",
              "s3:GetObject",
              "s3:DeleteObject",
              "s3:PutObject"
          ],
          "Resource": [
              "arn:aws:s3:::${local.metrics_bucket}/*",
              "arn:aws:s3:::${local.metrics_bucket}",
              "arn:aws:s3:::${local.log_bucket}/*",
              "arn:aws:s3:::${local.log_bucket}",
              "arn:aws:s3:::${local.traces_bucket}/*",
              "arn:aws:s3:::${local.traces_bucket}"
          ]
      }
    ]
}
EOF
}

resource "aws_s3_bucket" "metrics" {
  count  = var.create_buckets ? 1 : 0
  bucket = "${var.cluster_name}-metrics"

  tags = var.tags
}

resource "aws_s3_bucket" "logs" {
  count  = var.create_buckets ? 1 : 0
  bucket = "${var.cluster_name}-logs"

  tags = var.tags
}

resource "aws_s3_bucket" "traces" {
  count  = var.create_buckets ? 1 : 0
  bucket = "${var.cluster_name}-traces"

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "metrics" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.metrics[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "log" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "traces" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.traces[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "iam_policy_cloudwatch" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${var.cluster_name}-cloudwatch-policy"
  path        = "/"
  description = "Manage Cloudwatch metrics and logs"

  tags = var.tags

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "AllowReadingMetricsFromCloudWatch",
          "Effect": "Allow",
          "Action": [
              "cloudwatch:DescribeAlarmsForMetric",
              "cloudwatch:DescribeAlarmHistory",
              "cloudwatch:DescribeAlarms",
              "cloudwatch:ListMetrics",
              "cloudwatch:GetMetricData",
              "cloudwatch:GetInsightRuleReport"
          ],
          "Resource": "*"
      },
      {
          "Sid": "AllowReadingLogsFromCloudWatch",
          "Effect": "Allow",
          "Action": [
              "logs:DescribeLogGroups",
              "logs:GetLogGroupFields",
              "logs:StartQuery",
              "logs:StopQuery",
              "logs:GetQueryResults",
              "logs:GetLogEvents"
          ],
          "Resource": "*"
      },
      {
          "Sid": "AllowReadingTagsInstancesRegionsFromEC2",
          "Effect": "Allow",
          "Action": [
              "ec2:DescribeTags",
              "ec2:DescribeInstances",
              "ec2:DescribeRegions"
          ],
          "Resource": "*"
      },
      {
          "Sid": "AllowReadingResourcesForTags",
          "Effect": "Allow",
          "Action": "tag:GetResources",
          "Resource": "*"
      }
    ]
}
EOF
}

##########################################
# IAM assumable role with custom policies
##########################################
module "iam_assumable_role_monitor" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_arns = [
    module.iam_user.iam_user_arn,
  ]

  create_role = true

  role_name         = "${var.cluster_name}-monitor-role"
  role_requires_mfa = false

  custom_role_policy_arns = [
    module.iam_policy_cloudwatch.arn,
    try(module.iam_policy_s3[0].arn, ""),
  ]

  tags = var.tags
}

resource "aws_iam_policy_attachment" "cloudwatch-attach" {
  name       = "${var.cluster_name}-monitor-attachment"
  users      = [module.iam_user.iam_user_name]
  roles      = [module.iam_assumable_role_monitor.iam_role_name]
  policy_arn = module.iam_policy_cloudwatch.arn
}

resource "aws_iam_policy_attachment" "s3-attach" {
  name       = "${var.cluster_name}-monitor-attachment"
  users      = [module.iam_user.iam_user_name]
  roles      = [module.iam_assumable_role_monitor.iam_role_name]
  policy_arn = try(module.iam_policy_s3[0].arn, "")
}
