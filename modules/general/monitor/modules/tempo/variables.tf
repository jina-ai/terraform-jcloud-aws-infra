variable "namespace" {
  description = "Tempo namespace"
  default     = ""
}

variable "tempo_overwrite_values_yaml_body" {
  description = "Overwrite Tempo Values in YAML. Please refer to https://github.com/grafana/helm-charts/blob/main/charts/tempo-distributed/values.yaml for all possible values you can set."
  default     = ""
}

variable "traces_bucket_region" {
  description = "Trace S3 Bucket Region"
  default     = ""
  validation {
    condition     = var.traces_bucket_region != ""
    error_message = "If Tempo is enabled but Monitor Store is disabled, please also provide Trace Bucket Region (traces_bucket_region)"
  }
}

variable "traces_bucket_name" {
  description = "Trace Bucket Name"
  default     = ""
  validation {
    condition     = var.traces_bucket_name != ""
    error_message = "If Tempo is enabled but Monitor Store is disabled, please also provide Trace Bucket Name (traces_bucket)"
  }
}

variable "monitor_iam_access_key_id" {
  description = "Monitor User Access Key ID"
  default     = ""
  validation {
    condition     = var.monitor_iam_access_key_id != ""
    error_message = "If Tempo is enabled but Monitor Store is disabled, please also provide Monitor IAM Access Key ID (monitor_iam_access_key_id)"
  }
}

variable "monitor_iam_access_key_secret" {
  description = "Monitor Access Key secret"
  default     = ""
  validation {
    condition     = var.monitor_iam_access_key_secret != ""
    error_message = "If Tempo is enabled but Monitor Store is disabled, please also provide Monitor IAM Access Key Secret (monitor_iam_access_key_secret)"
  }
}
