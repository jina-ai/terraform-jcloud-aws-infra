##############################################
# Common Module Variables
##############################################

variable "cluster_name" {
  description = "JCloud Cluster Name"
  type        = string
  default     = ""
}

variable "monitor_iam_access_key_id" {
  description = "Monitor IAM Access Key ID"
  default     = ""
}

variable "monitor_iam_access_key_secret" {
  description = "Monitor IAM Access Key Secret"
  default     = ""
}

variable "enable_metrics" {
  description = "If set to true, Prometheus and DCGM Exporter will be enabled, and corresponding toggles (i.e enable_prometheus, enable_dcgm_exporter) will be overwritten"
  default     = false
}

variable "enable_logging" {
  description = "If set to true, Promtail will be enabled, and corresponding toggles (i.e. enable_loki, enable_promtail) will be overwritten"
  default     = false
}

variable "enable_tracing" {
  description = "If set to true, Tempo and OTLP Collector will be enabled, and corresponding toggles (i.e enable_tempo, enable_otlp_collector) will be overwritten"
  default     = false
}

##############################################
# Prometheus Module Variables
##############################################

variable "enable_prometheus" {
  description = "Whether Prometheus is Enabled"
  type        = bool
  default     = false
}

variable "alertmanager_config_yaml_body" {
  description = "Prometheus' Alertmanager Values in YAML Format"
  type        = string
  default     = ""
}

variable "enable_grafana" {
  description = "Whether Grafana is Enabled"
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
#   description = "Grafana Ingress TLS Secret Name. Ignored if grafana_ingress_yaml_body is set"
#   type        = string
#   default     = ""
# }

# variable "grafana_ingress_class_name" {
#   description = "Grafana Ingress Class Name. Ignored if grafana_ingress_yaml_body is set."
#   type        = string
#   default     = "kong"
# }


# variable "grafana_ingress_yaml_body" {
#   description = "Grafana Ingress Values in YAML Format. This overwrites grafana_ingress_tls_secret_name and grafana_ingress_class_name"
#   type        = string
#   default     = ""
# }

variable "prometheus_otlp_collector_scrape_endpoint" {
  description = "OTLP Collector Scrape Endpoint"
  default     = "kube-otlp-collector-opentelemetry-collector.monitor.svc.cluster.local:8888"
}

variable "prometheus_stack_overwrite_values_yaml_body" {
  description = "Overwrite Prometheus-Stack Values in YAML Format. Please refer to https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml for all possible values you can set."
  type        = string
  default     = ""
}

##############################################
# Thanos Module Variables
##############################################

variable "enable_thanos" {
  description = "Whether Thanos is Enabled"
  type        = bool
  default     = false
}

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

variable "thanos_overwrite_values_yaml_body" {
  description = "Thanos Overwrite Values in YAML"
  default     = ""
}


variable "metrics_bucket_region" {
  description = "Metric Bucket Region"
  default     = ""
}


##############################################
# Promtail Module Variables
##############################################

variable "promtail_overwrite_values_yaml_body" {
  description = "Overwrite Promtail Values in YAML"
  default     = ""
}

variable "enable_promtail" {
  description = "Whether Promtail is enabled"
  type        = bool
  default     = false
}

variable "promtail_clients_urls" {
  description = "Promtail's Clients' URLS to push logs to"
  type        = list(string)
  default     = ["http://kube-loki.monitor.svc.cluster.local:3100/loki/api/v1/push"]
}

##############################################
# Loki Module Variables
##############################################

variable "enable_loki" {
  description = "Whether Loki is enabled"
  type        = bool
  default     = false
}

variable "loki_overwrite_values_yaml_body" {
  description = "Overwrite Loki Values in YAML"
  default     = ""
}

variable "log_bucket_region" {
  description = "Log Bucket Region"
  default     = ""
}

##############################################
# Tempo Module Variables
##############################################

variable "enable_tempo" {
  description = "Whether to enable Tempo for tracing"
  type        = bool
  default     = false
}

variable "tempo_overwrite_values_yaml_body" {
  description = "Overwrite Tempo Values in YAML. Please refer to https://github.com/grafana/helm-charts/blob/main/charts/tempo-distributed/values.yaml for all possible values you can set."
  default     = ""
}

variable "traces_bucket_region" {
  description = "Trace S3 Bucket Region"
  default     = ""
}

##############################################
# OTLP Collector Module Variables
##############################################

variable "enable_otlp_collector" {
  description = "Whether to enable OTLP Collector"
  type        = bool
  default     = false
}

variable "otlp_endpoint" {
  description = "OTLP Endpoint"
  default     = "kube-tempo-distributor:4317"
}

variable "otlp_collector_overwrite_values_yaml_body" {
  description = "Overwrite OTLP Collector Values in YAML"
  default     = ""
}

##############################################
# OTLP Collector Module Variables
##############################################

variable "enable_dcgm_exporter" {
  description = "Whether to enable DCGM Exporter"
  default     = false
}

##############################################
# Monitor Store Module Variables
##############################################

variable "enable_monitor_store" {
  description = "Whether to enable monitor store"
  type        = bool
  default     = false
}

variable "create_buckets" {
  description = "Jcloud monitor bucket"
  type        = bool
  default     = true
}

variable "create_grafana_database" {
  description = "Jcloud monitor grafana database"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for AWS Resource"
  type        = map(string)
  default     = {}
}

variable "metrics_bucket" {
  description = "Jcloud metrics bucket name"
  type        = string
  default     = ""
}

variable "log_bucket" {
  description = "Jcloud log bucket name"
  type        = string
  default     = ""
}

variable "traces_bucket" {
  description = "Jcloud traces bucket name"
  type        = string
  default     = ""
}