variable "oidc_provider_arn" {
  description = "EKS oidc arn for service account"
  type        = string
  default     = ""
}


variable "domain_filters" {
  description = "The domain filters for external dns"
  type        = string
  default     = "{wolf.jina.ai,dev.jina.ai,docsqa.jina.ai}"
}


variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = ""
}

variable "app_ref" {
  description = "EKS Cluster Name Suffix"
  type        = string
  default     = ""
}

variable "remote_role" {
  description = "Remote AWS external dns role"
  type        = string
  default     = ""
}

variable "external_dns_role" {
  description = "External AWS external dns role"
  type        = string
  default     = ""
}

variable "trigger_by_events" {
  description = "External DNS update by events"
  type        = bool
  default     = true
}