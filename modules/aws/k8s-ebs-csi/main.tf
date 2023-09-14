data "aws_region" "current" {}


data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.30.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${var.cluster_name}"
  provider_url                  = replace(data.aws_eks_cluster.eks.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "helm_release" "ebs-csi" {
  namespace        = var.namespace
  create_namespace = true

  values = ["${file("${path.module}/tolerations.yaml")}"]

  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = "2.12.1"

  set {
    name  = "controller.serviceAccount.create"
    value = true
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa-ebs-csi.iam_role_arn
    type  = "string"
  }

  set {
    name  = "controller.nodeSelector.jina\\.ai/node-type"
    value = "system"
    type  = "string"
  }


  depends_on = [
    module.irsa-ebs-csi
  ]
}

resource "kubectl_manifest" "ebs_sc" {
  yaml_body = <<-YAML
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: ebs-sc
  provisioner: ebs.csi.aws.com
  volumeBindingMode: ${var.binding_mode}
  reclaimPolicy: Delete
  allowVolumeExpansion: true
  YAML
}
