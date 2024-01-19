# Backend
terraform {
  backend "s3" {
    bucket = "jina-terraform-state"
    key    = "jcloud/stage/eks/us-east-1"
    region = "us-east-2"
  }
}
