variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = ""
}

variable "cluster_region" {
  description = "Region of the AWS resources"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "cluster autoscaler install namespace"
  type        = string
  default     = "wolf"
}

variable "oidc_provider_arn" {
  description = "EKS oidc arn for service account"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for AWS Resource"
  type        = map(string)
  default     = {}
}
