variable "tls_secret_name" {
  description = "tls cert secret name"
  type        = string
  default     = ""
}


variable "issuer_email" {
  description = "cert issuer email"
  type        = string
  default     = ""
}


variable "domain" {
  description = "tls cert domain"
  type        = string
  default     = ""
}

variable "region" {
  description = "route 53 region"
  type        = string
  default     = ""
}

variable "zone_id" {
  description = "route 53 zone id"
  type        = string
  default     = ""
}
