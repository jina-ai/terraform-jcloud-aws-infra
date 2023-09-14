variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "EFS csi drive install namespace"
  type        = string
  default     = "kube-system"
}

variable "oidc_provider_arn" {
  description = "EKS oidc arn for service account"
  type        = string
  default     = ""
}
