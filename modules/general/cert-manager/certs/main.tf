resource "kubectl_manifest" "issuer" {
  yaml_body = <<-YAML
  apiVersion: cert-manager.io/v1
  kind: ClusterIssuer
  metadata:
    name: "letsencrypt-${var.tls_secret_name}"
  spec:
    acme:
      email: "${var.issuer_email}"
      server: https://acme-v02.api.letsencrypt.org/directory
      privateKeySecretRef:
        name: "letsencrypt-issuer-${var.tls_secret_name}"
      solvers:
        # example: cross-account zone management for example.com
        # this solver uses ambient credentials (i.e. inferred from the environment or EC2 Metadata Service)
        # to assume a role in a different account
        - selector:
            dnsZones:
              - "${var.domain}"
          dns01:
            route53:
              region: "${var.region}"
              hostedZoneID: "${var.zone_id}" # optional, see policy above
  YAML
}

resource "kubectl_manifest" "cert" {
  yaml_body = <<-YAML
  apiVersion: cert-manager.io/v1
  kind: Certificate
  metadata:
    annotations:
      jina.ai/synced-cert: 'true'
    name: ${var.tls_secret_name}
    namespace: cert-manager
  spec:
    dnsNames:
    - "*.${var.domain}"
    issuerRef:
      group: cert-manager.io
      kind: ClusterIssuer
      name: "letsencrypt-${var.tls_secret_name}"
    secretName: ${var.tls_secret_name}
    usages:
    - digital signature
    - key encipherment
    secretTemplate:
      annotations:
        reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
        reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "jnamespace-[a-z0-9]*"
        reflector.v1.k8s.emberstack.com/reflection-allowed: "true"  # permit replication
        reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: ""  # comma separated list of namespaces or regular expressions
  YAML

  depends_on = [kubectl_manifest.issuer]
}
