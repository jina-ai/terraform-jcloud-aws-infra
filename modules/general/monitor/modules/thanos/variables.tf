variable "namespace" {
  description = "Thanos Namespace"
  default = ""
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
  default = ""  
}

variable "metrics_bucket_name" {
  description = "Metric Bucket Name"
  default = ""
  validation {
    condition     = var.metrics_bucket_name != ""
    error_message = "If Thanos is enabled but Monitor Store is disabled, please also provide Metrics Bucket Name (metrics_bucket)"
  }
}

variable "metrics_bucket_region" {
  description = "Metric Bucket Region"
  default = ""
  validation {
    condition     = var.metrics_bucket_region != ""
    error_message = "If Thanos is enabled but Monitor Store is disabled, please also provide Metrics Bucket Name (metrics_bucket_region)"
  }
}

variable "monitor_iam_access_key_id" {
  description = "Monitor User Access Key ID"
  default     = ""
  validation {
    condition     = var.monitor_iam_access_key_id != ""
    error_message = "If Thanos is enabled but Monitor Store is disabled, please also provide Monitor IAM Access Key ID (monitor_iam_access_key_id)"
  }
}

variable "monitor_iam_access_key_secret" {
  description = "Monitor Access Key secret"
  default     = ""
  validation {
    condition     = var.monitor_iam_access_key_secret != ""
    error_message = "If Thanos is enabled but Monitor Store is disabled, please also provide Monitor IAM Access Key Secret (monitor_iam_access_key_secret)"
  }
}

