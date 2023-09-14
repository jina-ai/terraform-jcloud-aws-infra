variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "ebs csi driver namespace"
  type        = string
  default     = "kube-system"
}

variable "endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
  default     = "kube-system"
}

variable "binding_mode" {
  description = "Storage class binding mode"
  type        = string
  default     = "Immediate"
}

variable "certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
  default     = "kube-system"
}
