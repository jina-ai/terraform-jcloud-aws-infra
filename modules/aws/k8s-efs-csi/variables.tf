variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region of the AWS resources"
  type        = string
  default     = ""
}

variable "create_efs" {
  description = "Whether to create efs"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "allow_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  type        = string
  default     = "0.0.0.0/0"
}

variable "subnets" {
  description = "EFS mount point subnets id"
  type        = list(string)
  default     = []
}

variable "endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
  default     = "kube-system"
}

variable "certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
  default     = "kube-system"
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

variable "binding_mode" {
  description = "Storage class binding mode"
  type        = string
  default     = "Immediate"
}

variable "tags" {
  description = "Tags for AWS Resource"
  type        = map(string)
  default     = {}
}
