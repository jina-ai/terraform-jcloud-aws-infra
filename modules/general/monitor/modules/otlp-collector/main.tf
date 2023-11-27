resource "helm_release" "otlp_collector" {
  namespace        = var.namespace
  create_namespace = true

  name       = "kube-otlp-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"

  values = [file("${path.module}/default-otlp-collector-values.yaml"), var.otlp_collector_overwrite_values_yaml_body]

  set {
    name  = "config.exporters.otlp.tls.insecure"
    value = "true"
  }

  set {
    name  = "config.exporters.otlp.endpoint"
    value = var.otlp_endpoint
  }
}