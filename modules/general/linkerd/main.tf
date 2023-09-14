resource "helm_release" "linkerd-crds" {
  namespace        = "linkerd"
  create_namespace = true

  name       = "linkerd-crds"
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-crds"
  version    = "1.6.1"
}

resource "helm_release" "linkerd" {
  namespace        = "linkerd"
  create_namespace = true

  name       = "linkerd-control-plane"
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-control-plane"
  version    = "1.12.4"

  set {
    name  = "proxyInit.runAsRoot"
    value = true
  }

  set {
    name  = "nodeSelector.jina\\.ai/node-type"
    value = "system"
    type  = "string"
  }

  set_sensitive {
    name  = "identityTrustAnchorsPEM"
    value = tls_self_signed_cert.trustanchor_cert.cert_pem
  }

  set_sensitive {
    name  = "identity.issuer.tls.crtPEM"
    value = tls_locally_signed_cert.issuer_cert.cert_pem
  }

  set_sensitive {
    name  = "identity.issuer.tls.keyPEM"
    value = tls_private_key.issuer_key.private_key_pem
  }

  depends_on = [
    helm_release.linkerd-crds,
    tls_private_key.issuer_key,
    tls_locally_signed_cert.issuer_cert,
    tls_self_signed_cert.trustanchor_cert,
  ]
}
