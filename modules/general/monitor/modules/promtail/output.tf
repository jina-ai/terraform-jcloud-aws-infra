output "yaml_body" {
  value = yamlencode(merge([for v in helm_release.promtail.metadata[*].values : try(yamldecode(v), {})]...))
}