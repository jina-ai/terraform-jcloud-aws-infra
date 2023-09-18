resource "helm_release" "dcgm_exporter" {
  namespace        = var.namespace
  create_namespace = true

  name       = "dcgm-exporter"
  repository = "https://nvidia.github.io/dcgm-exporter/helm-charts"
  chart      = "dcgm-exporter"
  version    = "3.1.7"

  values = [file("${path.module}/default-dcgm-exporter-values.yaml")]
}