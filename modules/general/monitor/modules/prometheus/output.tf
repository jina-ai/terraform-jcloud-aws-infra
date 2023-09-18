output "yaml_body" {
  value = yamlencode(merge([for v in helm_release.prometheus_stack.metadata[*].values : try(yamldecode(v), {})]...))
}