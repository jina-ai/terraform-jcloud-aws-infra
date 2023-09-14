terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4"
    }
  }

  required_version = ">= 1.1.9"

}
