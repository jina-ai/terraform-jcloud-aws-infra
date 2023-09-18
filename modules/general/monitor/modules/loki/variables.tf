variable "loki_overwrite_values_yaml_body" {
  description = "Overwrite Loki Values in YAML"
  default     = ""
}

variable "namespace" {
  description = "Loki namespace"
  default     = ""
}

variable "log_bucket_region" {
  description = "Log S3 Bucket Region"
  default     = ""
  validation {
    condition     = var.log_bucket_region != ""
    error_message = "If Loki is enabled but Monitor Store is disabled, please also provide Log Bucket Region (log_bucket_region)"
  }
}

variable "log_bucket_name" {
  description = "Log Bucket Name"
  default     = ""
  validation {
    condition     = var.log_bucket_name != ""
    error_message = "If Loki is enabled but Monitor Store is disabled, please also provide Log Bucket Name (log_bucket)"
  }
}

variable "monitor_iam_access_key_id" {
  description = "Monitor User Access Key ID"
  default     = ""
  validation {
    condition     = var.monitor_iam_access_key_id != ""
    error_message = "If Loki is enabled but Monitor Store is disabled, please also provide Monitor IAM Access Key ID (monitor_iam_access_key_id)"
  }
}

variable "monitor_iam_access_key_secret" {
  description = "Monitor Access Key secret"
  default     = ""
  validation {
    condition     = var.monitor_iam_access_key_secret != ""
    error_message = "If Loki is enabled but Monitor Store is disabled, please also provide Monitor IAM Access Key Secret (monitor_iam_access_key_secret)"
  }
}