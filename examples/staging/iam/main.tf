terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.67.0"
    }
  }

  required_version = ">= 1.1.9"
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  # profile = "jina"
  default_tags {
    tags = {
      Team        = "Infra"
      Project     = "jcloud"
      Environment = "local"
      Terraform   = "true"
    }
  }
}


locals {
  local_cluster_oidc = "arn:aws:iam::253352124568:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/302701DDDEFC5A36B1E906CE99C792DE"
}

data "aws_iam_policy_document" "jcloud_ecr_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.local_cluster_oidc]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(local.local_cluster_oidc, "/^(.*provider/)/", "")}:sub"
      values   = ["system:serviceaccount:wolf:jina-ecr-reader"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(local.local_cluster_oidc, "/^(.*provider/)/", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "daemonset-reader" {
  name               = "daemonset-reader-stage-abcde"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.jcloud_ecr_assume_role_policy.json
}

resource "aws_iam_role_policy" "daemonset-reader-policy" {
  name = "daemonset-reader-policy"
  role = aws_iam_role.daemonset-reader.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:ListImages",
          "ecr:GetDownloadUrlForLayer"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::jina-embedding-models-us-east-1/*",
          "arn:aws:s3:::jina-embedding-models-us-east-1"
        ]
      }
    ]
  })
}

output "iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.daemonset-reader.arn
}
