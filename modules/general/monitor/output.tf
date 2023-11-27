output "prometheus_stack_yaml_body" {
  description = "Values in YAML of Prometheus"
  value       = try(module.prometheus_stack[0].yaml_body, "")
}

output "loki_yaml_body" {
  description = "Values in YAML of Loki"
  value       = try(module.loki[0].yaml_body, "")
}


output "tempo_yaml_body" {
  description = "Values in YAML of Tempo"
  value       = try(module.tempo[0].yaml_body, "")
}

output "promtail_yaml_body" {
  description = "Values in YAML of Promtail"
  value       = try(module.promtail[0].yaml_body, "")
}


output "otlp_collector_yaml_body" {
  description = "Values in YAML of OTLP Collector"
  value       = try(module.otlp_collector[0].yaml_body, "")
}