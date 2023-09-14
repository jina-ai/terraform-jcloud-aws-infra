data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

variable "wait_for_write" {
  type = string
}

locals {
  cluster_name   = var.cluster_name
  partition      = data.aws_partition.current.partition
  account_id     = data.aws_caller_identity.current.account_id
  enable_grafana = length(var.grafana_host) > 0 ? "false" : "true"
  metrics_bucket = length(var.kubecost_metric_buckets) > 0 ? var.kubecost_metric_buckets : "${var.cluster_name}-kubecost-metrics"
}

resource "kubernetes_secret" "kubecost_metrics_secret" {

  metadata {
    name      = "jcloud-monitor-store"
    namespace = "kubecost"
  }

  data = {
    "objstore.yml" = <<-YAML
type: S3
config:
  bucket: "${local.metrics_bucket}"
  endpoint: "s3.${var.s3_region}.amazonaws.com"
  region: "${var.s3_region}"
  access_key: "${module.iam_user.iam_access_key_id}"
  insecure: false
  signature_version2: false
  secret_key: "${module.iam_user.iam_access_key_secret}"
    YAML
  }

  depends_on = [
    aws_iam_user_policy_attachment.iam_reader_attachment
  ]
}

module "iam_policy_spot_data" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  name   = "${var.cluster_name}-spot-policy"
  path   = "/${var.cluster_name}/"
  tags   = var.tags
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:ListBucket",
                "s3:HeadBucket",
                "s3:HeadObject",
                "s3:List*",
                "s3:Get*"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "SpotDataAccess"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "spot-data-attach" {
  role       = aws_iam_role.kubecost_role.name
  policy_arn = module.iam_policy_spot_data.arn
}

module "iam_policy_athena" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  name   = "${var.cluster_name}-athena-policy"
  path   = "/${var.cluster_name}/"
  tags   = var.tags
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "athena:*"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "AthenaAccess"
        },
        {
            "Action": [
                "glue:GetDatabase*",
                "glue:GetTable*",
                "glue:GetPartition*",
                "glue:GetUserDefinedFunction",
                "glue:BatchGetPartition"
            ],
            "Resource": [
                "arn:aws:glue:*:*:catalog",
                "arn:aws:glue:*:*:database/athenacurcfn*",
                "arn:aws:glue:*:*:table/athenacurcfn*/*"
            ],
            "Effect": "Allow",
            "Sid": "ReadAccessToAthenaCurDataViaGlue"
        },
        {
            "Action": [
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload",
                "s3:CreateBucket",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::aws-athena-query-results-*"
            ],
            "Effect": "Allow",
            "Sid": "AthenaQueryResultsOutput"
        },
        {
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::aws-athena-query-results-jcloud-kubecost-prod*"
            ],
            "Effect": "Allow",
            "Sid": "S3ReadAccessToAwsBillingData"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "athena-attach" {
  role       = aws_iam_role.kubecost_role.name
  policy_arn = module.iam_policy_athena.arn
}

resource "aws_iam_role_policy_attachment" "ec2-readonly-attach" {
  role       = aws_iam_role.kubecost_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

data "aws_eks_cluster" "main" {
  name = var.cluster_name
}

data "aws_iam_policy_document" "assume_role_with_oidc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"

      identifiers = [
        "arn:${local.partition}:iam::${local.account_id}:oidc-provider/${replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kubecost:kubecost-cost-analyzer"]
    }
  }
}

resource "aws_iam_role" "kubecost_role" {
  assume_role_policy    = data.aws_iam_policy_document.assume_role_with_oidc.json
  force_detach_policies = false
  max_session_duration  = 43200
  name                  = "${var.cluster_name}-kubecost"
  path                  = "/"
  tags                  = var.tags
}

resource "helm_release" "kubecost_prom" {
  namespace        = "kubecost"
  create_namespace = true

  name       = "kubecost-prom"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.1.1"

  values = ["${templatefile("${path.module}/prometheus/prom-values.yaml", { cluster_name = "${local.cluster_name}" })}"]

  depends_on = [
    kubernetes_secret.kubecost_metrics_secret
  ]
}

resource "helm_release" "kubecost_thanos" {
  namespace        = "kubecost"
  create_namespace = true

  name       = "thanos"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "thanos"
  version    = "12.0.6"

  values = ["${templatefile("${path.module}/prometheus/thanos-values.yaml", { cluster_name = "${local.cluster_name}" })}"]

  depends_on = [
    kubernetes_secret.kubecost_metrics_secret
  ]
}

resource "helm_release" "kubecost" {
  namespace        = "kubecost"
  create_namespace = true

  name       = "kubecost"
  repository = "https://kubecost.github.io/cost-analyzer"
  chart      = "cost-analyzer"
  version    = "1.98.0"

  values = ["${templatefile("${path.module}/kubecost-values.yaml", { cluster_name = "${local.cluster_name}", aws_account = "${local.account_id}", athena_bucket = "${var.athena_bucket}", athena_region = "${var.athena_region}", athena_table = "${var.athena_table}", grafana_host = "${var.grafana_host}", enable_grafana = "${local.enable_grafana}" })}"]

  set {
    name  = "kubecostProductConfigs.clusterName"
    value = local.cluster_name
  }

  set {
    name  = "kubecostProductConfigs.athenaProjectID"
    value = local.account_id
  }

  set {
    name  = "kubecostProductConfigs.athenaBucketName"
    value = var.athena_bucket
  }

  set {
    name  = "kubecostProductConfigs.athenaRegion"
    value = var.athena_region
  }

  set {
    name  = "kubecostProductConfigs.athenaDatabase"
    value = "athenacurcfn_jcloud_cost_report" // Hard coded athena db
  }

  set {
    name  = "kubecostProductConfigs.athenaTable"
    value = "external-dns"
  }

  # TODO: need to look into this

  set {
    name  = "kubecostProductConfigs.awsSpotDataRegion"
    value = var.athena_region
  }

  set {
    name  = "kubecostProductConfigs.projectID"
    value = local.account_id
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.kubecost_role.arn
    type  = "string"
  }

  set {
    name  = "kubecostModel.warmCache"
    value = var.master
  }

  set {
    name  = "kubecostModel.warmSavingsCache"
    value = var.master
  }

  set {
    name  = "kubecostModel.etl"
    value = var.master
  }

  depends_on = [
    aws_iam_role.kubecost_role,
    helm_release.kubecost_prom,
    helm_release.kubecost_thanos
  ]
}
