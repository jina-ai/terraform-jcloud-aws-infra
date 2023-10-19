variable "node_selector" {
  description = "Node selector"
  type        = map(any)
  default     = {}
}

variable "namespace" {
  description = "Nvidia drive install namespace"
  type        = string
  default     = "nvidia-device-plugin"
}

variable "slicing_replicas" {
  description = "Shared GPU slice number"
  type        = number
  default     = 3
}
