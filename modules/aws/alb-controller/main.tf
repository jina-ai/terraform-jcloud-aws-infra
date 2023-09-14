data "aws_region" "current" {}

resource "helm_release" "alb_controller" {
  namespace        = var.namespace
  create_namespace = true

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "v1.4.3"

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller-sa"
    type  = "string"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa.iam_role_arn
    type  = "string"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
    type  = "string"
  }

  depends_on = [
    module.aws_load_balancer_controller_irsa
  ]
}

module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name                              = "aws_load_balancer_controller_${var.cluster_name}"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:aws-load-balancer-controller-sa"]
    }
  }
}
