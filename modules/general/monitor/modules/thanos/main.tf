locals {
  s3_config = <<-YAML
  type: S3
  config:
    bucket: "${var.metrics_bucket_name}"
    endpoint: "s3.${var.metrics_bucket_region}.amazonaws.com"
    region: "${var.metrics_bucket_region}"
    access_key: "${var.monitor_iam_access_key_id}"
    insecure: false
    signature_version2: false
    secret_key: "${var.monitor_iam_access_key_secret}"
  YAML
}

resource "helm_release" "thanos" {
  namespace        = var.namespace
  create_namespace = true

  name       = "kube-thanos"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "thanos"
  version    = "12.13.5"

  values = [
    file("${path.module}/default-thanos-values.yaml"), 
    var.thanos_overwrite_values_yaml_body, 
  ]

  set {
    name  = "existingObjstoreSecret"
    value = var.thanos_object_storage_config_name
  }
}

resource "kubernetes_secret" "jcloud_monitor_store" {
  metadata {
    name = var.thanos_object_storage_config_name
    namespace = var.namespace
  }

  data = {
    "${var.thanos_object_storage_config_key}" = local.s3_config
  }
}