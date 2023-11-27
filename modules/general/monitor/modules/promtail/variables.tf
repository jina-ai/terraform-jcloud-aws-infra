variable "promtail_overwrite_values_yaml_body" {
  description = "Overwrite Promtail Values in YAML"
  default     = ""
}

variable "namespace" {
  description = "Promtail namespace"
  default     = ""
}

variable "clients_urls" {
  description = "Clients URLs"
  type        = list(string)
  default     = ["http://kube-loki.monitor.svc.cluster.local:3100/loki/api/v1/push"]
}