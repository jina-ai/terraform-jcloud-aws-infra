terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
  }

  required_version = ">= 1.5.5"
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = module.jcloud.cluster_endpoint
    cluster_ca_certificate = base64decode(module.jcloud.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.jcloud.cluster_name, "--region", var.region]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.jcloud.cluster_endpoint
  cluster_ca_certificate = base64decode(module.jcloud.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.jcloud.cluster_name, "--region", var.region]
  }
}

provider "kubernetes" {
  host                   = module.jcloud.cluster_endpoint
  cluster_ca_certificate = base64decode(module.jcloud.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.jcloud.cluster_name, "--region", var.region]
  }
}
