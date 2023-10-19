data "aws_region" "current" {}

locals {
  slicing_replicas = var.slicing_replicas != 0 ? var.slicing_replicas : 3
}

resource "helm_release" "nvidia_plugin" {
  namespace        = var.namespace
  create_namespace = true

  values = ["${file("${path.module}/tolerations.yaml")}"]

  name       = "nvidia-device-plugin"
  repository = "https://nvidia.github.io/k8s-device-plugin"
  chart      = "nvidia-device-plugin"
  version    = "v0.12.2"

  set {
    name  = "config.name"
    value = "nvidia-custom-configmap"
    type  = "string"
  }

  dynamic "set" {
    for_each = { for k, v in var.node_selector : k => v }
    content {
      name  = "nodeSelector.${replace(set.key, ".", "\\.")}"
      value = set.value
      type  = "string"
    }
  }

}

resource "kubectl_manifest" "nvidia_plugin_cm" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
        name: nvidia-custom-configmap
        namespace: ${var.namespace}
    data:
        default: |-
            version: v1
            flags:
                migStrategy: "none"
                failOnInitError: true
                nvidiaDriverRoot: "/"
                plugin:
                  passDeviceSpecs: false
                  deviceListStrategy: envvar
                  deviceIDStrategy: uuid
        shared_gpu: |-
            version: v1
            flags:
                migStrategy: "none"
                failOnInitError: true
                nvidiaDriverRoot: "/"
                plugin:
                  passDeviceSpecs: false
                  deviceListStrategy: envvar
                  deviceIDStrategy: uuid
            sharing:
                timeSlicing:
                  renameByDefault: false
                  resources:
                  - name: nvidia.com/gpu
                    replicas: ${local.slicing_replicas}
  YAML

  depends_on = [
    helm_release.nvidia_plugin
  ]
}
