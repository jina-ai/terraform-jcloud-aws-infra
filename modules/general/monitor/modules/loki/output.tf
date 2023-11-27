output "yaml_body" {
  value = yamlencode(merge([for v in helm_release.loki.metadata[*].values : try(yamldecode(v), {})]...))
}