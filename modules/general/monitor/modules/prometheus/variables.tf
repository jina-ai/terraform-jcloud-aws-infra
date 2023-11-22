variable "namespace" {
  description = "Namespace where Prometheus will be installed"
  type        = string
  default     = ""
}

variable "alertmanager_config_yaml_body" {
  description = "(Optional) Prometheus' Alertmanager Values in YAML format"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Cluster Name for Prometheus Labels"
  type        = string
  default     = ""
}

variable "enable_grafana" {
  description = "Whether grafana is enabled"
  type        = bool
  default     = false
}

variable "enable_thanos" {
  description = "Whether thanos is enabled"
  type        = bool
  default     = false
}

variable "grafana_settings" {
  description = "Grafana Database Credentials"
  type        = map(any)
  default     = {}
}

# variable "grafana_additional_data_sources_yaml_body" {
#   description = "(Optional) Grafana Additional Data Sources List in YAML Format. If not provided, use default data sources"
#   type        = string
#   default     = false
# }

# variable "grafana_server_domain" {
#   description = "Grafana Server Domain"
#   type        = string
#   default     = ""
# }

# variable "grafana_database" {
#   description = "Grafana Database Credentials"
#   type        = map(string)
#   default     = {
#     user     = ""
#     password = ""
#     type     = ""
#     host     = ""
#   }
# }

# variable "grafana_admin_password" {
#   description = "Grafana Admin Password"
#   type        = string
#   default     = ""
# }

# variable "grafana_ingress_tls_secret_name" {
#   description = "Grafana Ingress TLS Secret Name. Ignored if grafana_ingress_yaml_body is set."
#   type        = string
#   default     = ""
# }

# variable "grafana_ingress_class_name" {
#   description = "Grafana Ingress Class Name. Ignored if grafana_ingress_yaml_body is set."
#   type        = string
#   default     = "kong"
# }

# variable "grafana_ingress_yaml_body" {
#   description = "(Optional) Grafana Ingress Values in YAML Format. This overwrites grafana_ingress_tls_secret_name and grafana_ingress_class_name"
#   type        = string
#   default     = ""
# }

variable "thanos_object_storage_config_name" {
  description = "Thanos object storage name"
  type        = string
  default     = "jcloud-monitor-store"
}

variable "thanos_object_storage_config_key" {
  description = "Thanos object storage name"
  type        = string
  default     = "objstore.yml"
}

variable "enable_loki" {
  description = "Whether Loki is enabled"
  type        = bool
  default     = false
}

variable "enable_tempo" {
  description = "Whether Tempo is enabled"
  type        = bool
  default     = false
}

variable "enable_otlp_collector" {
  description = "Whether OTLP Collector is enabled"
  type        = bool
  default     = false
}


variable "enable_metrics" {
  description = "If enabled,  enable_thanos will be overwritten to true"
  default     = false
  type        = bool
}

variable "enable_logging" {
  description = "If enabled,  enable_loki will be overwritten to true"
  default     = false
  type        = bool
}

variable "enable_tracing" {
  description = "If enabled,  enable_tempo will be overwritten to true"
  default     = false
  type        = bool
}

variable "prometheus_otlp_collector_scrape_endpoint" {
  description = "OTLP Collector Scrape Endpoint"
  default     = "kube-otlp-collector-opentelemetry-collector.monitor.svc.cluster.local:8888"
}

variable "prometheus_stack_overwrite_values_yaml_body" {
  description = "(Optional) Overwrite Prometheus-Stack Values in YAML Format. Please refer to https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml for all possible values you can set."
  type        = string
  default     = ""
}

variable "remote_write_url" {
  description = "If thanos is deployed in another cluster, you can provide remote_write_url to specify the address data should be written to"
  default = ""
}