module "cert_manager_irsa" {
  count   = var.remote_cert_manager_role == "" ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name                  = "jcloud-cert-manager-${var.cluster_name}"
  attach_cert_manager_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:jcloud-cert-manager"]
    }
  }
}

resource "helm_release" "reflector" {
  namespace        = "cert-manager"
  create_namespace = true

  name       = "reflector"
  repository = "https://emberstack.github.io/helm-charts"
  chart      = "reflector"

  set {
    name  = "nodeSelector.jina\\.ai/node-type"
    value = "system"
    type  = "string"
  }
}

resource "helm_release" "cert_manager" {
  namespace        = "cert-manager"
  create_namespace = true

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.12.0"

  set {
    name  = "serviceAccount.name"
    value = "jcloud-cert-manager"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = try(module.cert_manager_irsa[0].iam_role_arn, var.remote_cert_manager_role)
    type  = "string"
  }

  set {
    name  = "nodeSelector.jina\\.ai/node-type"
    value = "system"
    type  = "string"
  }

  depends_on = [
    kubectl_manifest.cert_manager_crd
  ]
}

data "kubectl_file_documents" "crds" {
  content = file("${path.module}/crds.yaml")
}

resource "kubectl_manifest" "cert_manager_crd" {
  count     = length(data.kubectl_file_documents.crds.documents)
  yaml_body = element(data.kubectl_file_documents.crds.documents, count.index)
  depends_on = [
    module.cert_manager_irsa
  ]
}

module "cert_manager_certs" {
  for_each = {
    for index, cert in var.certs :
    cert.domain => cert
  }
  source = "./certs"

  region          = each.value.region
  zone_id         = each.value.zone_id
  domain          = each.value.domain
  tls_secret_name = each.value.tls_secret_name
  issuer_email    = each.value.issuer_email
  depends_on = [
    helm_release.cert_manager
  ]
}
