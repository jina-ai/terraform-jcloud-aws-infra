variable "remote_cert_manager_role" {
  description = "remote role for cert manager"
  type        = string
  default     = ""
}


variable "oidc_provider_arn" {
  description = "EKS oidc arn for service account"
  type        = string
  default     = ""
}


variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = ""
}

variable "certs" {
  description = "JCloud ingress certs"
  type        = list(map(string))
  default     = []
}
