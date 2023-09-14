terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }

  required_version = ">= 1.1.9"
}
