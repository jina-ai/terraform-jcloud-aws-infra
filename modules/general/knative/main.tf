data "kubectl_file_documents" "serving-crds" {
  content = file("${path.module}/serving-crds.yaml")
}

data "kubectl_file_documents" "serving-core" {
  content = file("${path.module}/serving-core.yaml")
}

data "kubectl_file_documents" "serving-deploys" {
  content = file("${path.module}/serving-deploy.yaml")
}

data "kubectl_file_documents" "serving-hpa" {
  content = file("${path.module}/serving-hpa.yaml")
}

data "kubectl_file_documents" "serving-webhooks" {
  content = file("${path.module}/serving-webhooks.yaml")
}

data "kubectl_file_documents" "kourier" {
  content = file("${path.module}/kourier.yaml")
}

locals {
  crds_length     = try(length(data.kubectl_file_documents.serving-crds.documents), 0)
  core_length     = try(length(data.kubectl_file_documents.serving-core.documents), 0)
  deploy_length   = try(length(data.kubectl_file_documents.serving-deploys.documents), 0)
  hpa_length      = try(length(data.kubectl_file_documents.serving-hpa.documents), 0)
  webhooks_length = try(length(data.kubectl_file_documents.serving-webhooks.documents), 0)
  kourier_length  = try(length(data.kubectl_file_documents.kourier.documents), 0)
}

resource "kubernetes_namespace" "knative-serving" {
  metadata {
    annotations = {
      "linkerd.io/inject" = "enabled"
    }

    labels = {
      "app.kubernetes.io/name"    = "knative-serving",
      "app.kubernetes.io/version" = "1.10.0",
    }

    name = "knative-serving"
  }
  timeouts {
    delete = "15m"
  }
  depends_on = [var.cluster_endpoint]
}

resource "kubernetes_namespace" "kourier-system" {
  metadata {
    annotations = {
      "linkerd.io/inject" = "enabled"
    }

    labels = {
      "networking.knative.dev/ingress-provider" = "kourier",
      "app.kubernetes.io/name"                  = "knative-serving",
      "app.kubernetes.io/component"             = "net-kourier",
      "app.kubernetes.io/version"               = "1.10.0",
    }

    name = "kourier-system"
  }
  depends_on = [var.cluster_endpoint]
}

resource "kubectl_manifest" "serving-crds-resources" {
  count      = local.crds_length
  yaml_body  = element(data.kubectl_file_documents.serving-crds.documents, count.index)
  force_new  = true
  depends_on = [var.cluster_endpoint]
}

resource "kubectl_manifest" "serving-core-resources" {
  count      = local.core_length
  yaml_body  = element(data.kubectl_file_documents.serving-core.documents, count.index)
  force_new  = true
  depends_on = [kubectl_manifest.serving-crds-resources, kubernetes_namespace.knative-serving]
}

resource "kubectl_manifest" "serving-deploy-resources" {
  count      = local.deploy_length
  yaml_body  = element(data.kubectl_file_documents.serving-deploys.documents, count.index)
  force_new  = true
  depends_on = [kubectl_manifest.serving-core-resources]
}

resource "kubectl_manifest" "serving-hpa-resources" {
  count      = local.hpa_length
  yaml_body  = element(data.kubectl_file_documents.serving-hpa.documents, count.index)
  force_new  = true
  depends_on = [kubectl_manifest.serving-core-resources]
}

resource "kubectl_manifest" "serving-webhooks-resources" {
  count      = local.webhooks_length
  yaml_body  = element(data.kubectl_file_documents.serving-webhooks.documents, count.index)
  force_new  = true
  depends_on = [kubectl_manifest.serving-deploy-resources]
}

resource "kubernetes_config_map_v1_data" "config-domain" {
  metadata {
    name      = "config-domain"
    namespace = "knative-serving"
  }
  data = {
    "svc.wolf.internal" = <<YAML
selector:
    jina.ai/autoscale.expose: "true"
YAML
  }
  force      = true
  depends_on = [kubectl_manifest.serving-core-resources]
}

resource "kubernetes_config_map_v1_data" "config-features" {
  metadata {
    name      = "config-features"
    namespace = "knative-serving"
  }
  data = {
    "kubernetes.podspec-nodeselector"            = "enabled",
    "kubernetes.podspec-persistent-volume-claim" = "enabled",
    "kubernetes.podspec-persistent-volume-write" = "enabled",
    "kubernetes.podspec-fieldref"                = "enabled",
    "kubernetes.podspec-volumes-emptydir"        = "enabled",
  }
  force      = true
  depends_on = [kubectl_manifest.serving-core-resources]

}

resource "kubectl_manifest" "kourier" {
  count      = local.kourier_length
  yaml_body  = element(data.kubectl_file_documents.kourier.documents, count.index)
  force_new  = true
  depends_on = [kubectl_manifest.serving-core-resources, kubernetes_namespace.kourier-system]
}

resource "kubernetes_config_map_v1_data" "config-network" {
  metadata {
    name      = "config-network"
    namespace = "knative-serving"
  }
  data = {
    "ingress.class" = "kourier.ingress.networking.knative.dev",
  }
  force      = true
  depends_on = [kubectl_manifest.kourier, kubectl_manifest.serving-core-resources]
}
