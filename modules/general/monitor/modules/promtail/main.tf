resource "helm_release" "promtail" {
  namespace        = var.namespace
  create_namespace = true

  name       = "kube-promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"

  values = [file("${path.module}/default-promtail-values.yaml"), var.promtail_overwrite_values_yaml_body]

  dynamic "set" {
    for_each = var.clients_urls
    content {
      name  = "config.clients[${set.key}].url"
      value = set.value
      type  = "string"
    }
  }

}