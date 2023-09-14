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

