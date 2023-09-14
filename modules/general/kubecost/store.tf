module "iam_user" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  name          = "${var.cluster_name}-kubecost-user"
  path          = "/${var.cluster_name}/"
  force_destroy = true

  password_reset_required = false

  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "iam_reader_attachment" {
  user       = module.iam_user.iam_user_name
  policy_arn = module.iam_policy_s3.arn
}

module "iam_policy_s3" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${var.cluster_name}-kubecost-policy"
  path        = "/${var.cluster_name}/"
  description = "Manage kubecost bucket"

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
              "arn:aws:s3:::${local.metrics_bucket}"
          ]
      }
    ]
}
EOF
}

resource "aws_s3_bucket" "metrics" {
  count  = var.create_metrics_buckets ? 1 : 0
  bucket = "${var.cluster_name}-kubecost-metrics"

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "metrics" {
  count  = var.create_metrics_buckets ? 1 : 0
  bucket = aws_s3_bucket.metrics[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##########################################
# IAM assumable role with custom policies
##########################################
resource "aws_iam_role_policy_attachment" "kubecost-metrics-attach" {
  role       = aws_iam_role.kubecost_role.name
  policy_arn = module.iam_policy_s3.arn
}
