locals {
  aws_config = yamlencode({
    "storage" : {
      "trace" : {
        "backend" : "s3",
        "s3" : {
          "bucket" : var.traces_bucket_name,
          "endpoint" : "s3.${var.traces_bucket_region}.amazonaws.com",
          "access_key" : var.monitor_iam_access_key_id,
          "secret_key" : var.monitor_iam_access_key_secret,
          "insecure" : true,
        }
      }
    }
  })
}


resource "helm_release" "tempo" {
  namespace        = var.namespace
  create_namespace = true

  name       = "kube-tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo-distributed"
  version    = "1.4.0"

  values = [file("${path.module}/default-tempo-values.yaml"), local.aws_config, var.tempo_overwrite_values_yaml_body]
}