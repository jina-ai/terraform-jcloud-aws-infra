variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = ""
}

variable "grafana_host" {
  description = "kubecost grafana host"
  type        = string
  default     = ""
}

variable "athena_region" {
  description = "kubecost athena and spot data region"
  type        = string
  default     = "us-east-1"
}

variable "athena_bucket" {
  description = "kubecost athena bucket uri"
  type        = string
  default     = ""
}

variable "athena_table" {
  description = "kubecost athena table"
  type        = string
  default     = "jcloud_cost_report"
}

variable "s3_region" {
  description = "kubecost metrics bucket region"
  type        = string
  default     = "us-east-1"
}

variable "kubecost_metric_buckets" {
  description = "kubecost metric bucket name"
  type        = string
  default     = ""
}

variable "create_metrics_buckets" {
  description = "Whether create kubecost metrics bucket"
  type        = bool
  default     = false
}

variable "master" {
  description = "Whether is master kubecost"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for AWS Resource"
  type        = map(string)
  default     = {}
}
