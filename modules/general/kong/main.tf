data "kubectl_file_documents" "kong" {
  content = file("${path.module}/kong.yaml")
}

locals {
  deploy_length = try(length(data.kubectl_file_documents.kong.documents), 0)
}

resource "kubectl_manifest" "kong_resources" {
  count      = local.deploy_length
  yaml_body  = element(data.kubectl_file_documents.kong.documents, count.index)
  depends_on = [var.cluster_endpoint]
}
