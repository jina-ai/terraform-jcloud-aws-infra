output "yaml_body" {
  value = yamlencode(merge([for v in helm_release.otlp_collector.metadata[*].values : try(yamldecode(v), {})]...))
}