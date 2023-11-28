variable "cluster_name" {
  description = "Jcloud cluster name"
  type        = string
  default     = ""
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