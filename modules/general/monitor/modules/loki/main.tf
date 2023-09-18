locals {
  aws_config = yamlencode({
    "config" : {
      "storage_config" : {
        "aws" : {
          "s3forcepathstyle" : true
          "bucketnames" : var.log_bucket_name
          "region" : var.log_bucket_region
          "access_key_id" : var.monitor_iam_access_key_id
          "secret_access_key" : var.monitor_iam_access_key_secret
        }
      }
    }
  })
}

resource "helm_release" "loki" {
  namespace        = var.namespace
  create_namespace = true

  name       = "kube-loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "2.16.0"

  values = [file("${path.module}/default-loki-values.yaml"), local.aws_config, var.loki_overwrite_values_yaml_body]
}