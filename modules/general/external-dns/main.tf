module "external_dns_irsa" {
  count   = var.external_dns_role == "" && var.remote_role == "" ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name                  = "external_dns_${var.cluster_name}"
  attach_external_dns_policy = true

  oidc_providers = {
    external-dns = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["wolf:external-dns"]
    }
  }
}


resource "helm_release" "external_dns" {
  namespace        = "wolf"
  create_namespace = true

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.10.2"

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "txtPrefix"
    value = "${var.app_ref}-"
  }

  set {
    name  = "txtOwnerId"
    value = "${var.app_ref}-"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "interval"
    value = "3s"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
    type  = "string"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = try(module.external_dns_irsa[0].iam_role_arn, var.remote_role, var.external_dns_role)
    type  = "string"
  }

  set {
    name  = "domainFilters"
    value = var.domain_filters
    type  = "string"
  }

  set {
    name  = "provider"
    value = "aws"
    type  = "string"
  }

  # TODO: specify aws-zone-type

  set {
    name  = "registry"
    value = "txt"
    type  = "string"
  }

  set {
    name  = "txtOwnerId"
    value = "external-dns"
    type  = "string"
  }

  set {
    name  = "nodeSelector.jina\\.ai/node-type"
    value = "system"
    type  = "string"
  }

  set {
    name  = "triggerLoopOnEvent"
    value = var.trigger_by_events
  }

  set {
    name  = "extraArgs[0]"
    value = "--aws-batch-change-size=10"
    type  = "string"
  }

  dynamic "set" {
    for_each = var.remote_role != "" ? [1] : []
    content {
      name  = "extraArgs[1]"
      value = "--aws-assume-role=${var.remote_role}"
      type  = "string"
    }
  }

  depends_on = [
    module.external_dns_irsa
  ]
}
