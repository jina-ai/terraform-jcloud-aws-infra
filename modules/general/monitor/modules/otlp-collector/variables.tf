variable "otlp_endpoint" {
  description = "OTLP Endpoint"
  default     = "kube-tempo-distributor:4317"
}

variable "namespace" {
  description = "OTLP Collector Namespace"
  default     = ""
}

variable "otlp_collector_overwrite_values_yaml_body" {
  description = "Overwrite OTLP Collector Values in YAML"
  default     = ""
}