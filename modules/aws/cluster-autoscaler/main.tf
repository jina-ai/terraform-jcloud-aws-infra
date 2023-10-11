data "aws_region" "current" {}

module "iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name = "cluster_autoscaler_policy_${var.cluster_name}"
  path = "/"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        "Resource" : ["*"]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ],
        "Resource" : ["*"]
      }
    ]
  })

}

module "cluster-autoscaler-irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name = "cluster_autoscaler_${var.cluster_name}"

  attach_cluster_autoscaler_policy = true

  oidc_providers = {
    cluster-autoscaler = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["wolf:cluster-autoscaler"]
    }
  }
}

resource "helm_release" "cluster-autoscaler" {
  namespace        = var.namespace
  create_namespace = true

  name       = "autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.29.3"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.cluster_region
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = true
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster-autoscaler-irsa.iam_role_arn
    type  = "string"
  }

  set {
    name  = "controller.nodeSelector.jina\\.ai/node-type"
    value = "system"
    type  = "string"
  }

  depends_on = [
    module.cluster-autoscaler-irsa
  ]
}
