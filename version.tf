terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }
    random = {
      version = ">= 2.1.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4"
    }
  }

  required_version = ">= 1.3.0"
}
