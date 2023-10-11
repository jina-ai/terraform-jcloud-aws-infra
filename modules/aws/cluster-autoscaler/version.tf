terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.67.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4"
    }
  }

  required_version = ">= 1.5.5"

}
