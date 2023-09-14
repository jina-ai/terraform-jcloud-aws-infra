terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.67.0"
    }
    random = {
      version = ">= 2.1.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }

  required_version = ">= 1.1.9"

}

# Configure the AWS Provider
