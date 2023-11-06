locals {
  accelerator_labels = {
    "shared_gpu" = var.shared_gpu_node_labels,
    "gpu"        = var.gpu_node_labels
  }
  shared_gpu_instance_type = "[\"${join("\", \"", var.shared_gpu_instance_type)}\"]"
  gpu_instance_type        = "[\"${join("\", \"", var.gpu_instance_type)}\"]"
  standard_instance_type   = "[\"${join("\", \"", var.standard_instance_type)}\"]"
  system_instance_type     = "[\"${join("\", \"", var.system_instance_type)}\"]"
}

resource "aws_iam_instance_profile" "karpenter" {
  count = var.enable_karpenter ? 1 : 0
  name  = "KarpenterNodeInstanceProfile-${local.cluster_name}"
  role  = module.eks.eks_managed_node_groups["inital"].iam_role_name

  depends_on = [
    module.eks
  ]
}

module "karpenter_irsa" {
  count   = var.enable_karpenter ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.2.0"

  role_name                          = "karpenter-controller-${local.cluster_name}"
  attach_karpenter_controller_policy = true
  attach_vpc_cni_policy              = true

  karpenter_controller_cluster_id = module.eks.cluster_name
  karpenter_controller_ssm_parameter_arns = [
    "arn:${local.partition}:ssm:*:*:parameter/aws/service/*"
  ]
  karpenter_controller_node_iam_role_arns = [
    module.eks.eks_managed_node_groups["inital"].iam_role_arn
  ]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

resource "helm_release" "karpenter" {
  count            = var.enable_karpenter ? 1 : 0
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.31.1"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa[0].iam_role_arn
  }

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter[0].name
  }

  depends_on = [module.eks]
}

resource "kubectl_manifest" "karpenter_provisioner" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: "default"
  spec:
    consolidation:
        enabled: ${var.karpenter_consolidation_enable ? "true" : "false"}
    labels:
      jina.ai/node-type: standard
    requirements:
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ${local.standard_instance_type}
      - key: "topology.kubernetes.io/zone"
        operator: In
        values: ${local.vpc_regions}
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
    limits:
      resources:
        cpu: 1000
    provider:
      launchTemplate: "karpenter-default-${local.cluster_name}"
      subnetSelector:
        karpenter.sh/discovery: ${local.cluster_name}
      tags:
        karpenter.sh/discovery: ${local.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_provisioner_system" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: "system"
  spec:
    ttlSecondsAfterEmpty: 300
    labels:
      jina.ai/node-type: system
    requirements:
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ${local.system_instance_type}
      - key: "topology.kubernetes.io/zone"
        operator: In
        values: ${local.vpc_regions}
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
    limits:
      resources:
        cpu: 1000
    provider:
      launchTemplate: "karpenter-system-${local.cluster_name}"
      subnetSelector:
        karpenter.sh/discovery: ${local.cluster_name}
      tags:
        karpenter.sh/discovery: ${local.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_provisioner_privileged" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: "privileged"
  spec:
    ttlSecondsAfterEmpty: 300
    labels:
      jina.ai/node-type: privileged
    requirements:
      - key: karpenter.k8s.aws/instance-family
        operator: In
        values:
        - t3
        - c5
        - m5
        - r5
      - key: karpenter.k8s.aws/instance-size
        operator: NotIn
        values:
        - 8xlarge
        - 12xlarge
        - 16xlarge
        - 24xlarge
        - 32xlarge
        - metal
      - key: "topology.kubernetes.io/zone"
        operator: In
        values: ${local.vpc_regions}
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
    limits:
      resources:
        cpu: 1000
    provider:
      launchTemplate: "karpenter-default-${local.cluster_name}"
      subnetSelector:
        karpenter.sh/discovery: ${local.cluster_name}
      tags:
        karpenter.sh/discovery: ${local.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_provisioner_gpu_shared" {
  count     = var.enable_gpu && var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: "gpu-shared"
  spec:
    ttlSecondsAfterEmpty: 300
    labels:
      jina.ai/node-type: gpu-shared
      jina.ai/gpu-type: nvidia
      nvidia.com/device-plugin.config: shared_gpu
      ${yamlencode(local.accelerator_labels.shared_gpu)}
    affinity:
      podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  run: overprovisioning
              topologyKey: kubernetes.io/hostname
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            run: overprovisioning
    requirements:
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ${local.shared_gpu_instance_type}
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
    taints:
      - key: nvidia.com/gpu-shared
        effect: "NoSchedule"
    limits:
      resources:
        cpu: 1000
    provider:
      launchTemplate: "karpenter-gpu-shared-${local.cluster_name}"
      subnetSelector:
        karpenter.sh/discovery: ${local.cluster_name}
      tags:
        karpenter.sh/discovery: ${local.cluster_name}
    ttlSecondsAfterEmpty: 300
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_provisioner_gpu" {
  count     = var.enable_gpu && var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: "gpu"
  spec:
    ttlSecondsAfterEmpty: 300
    labels:
      jina.ai/node-type: gpu
      jina.ai/gpu-type: nvidia
      ${yamlencode(local.accelerator_labels.gpu)}
    requirements:
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ${local.gpu_instance_type}
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
    taints:
      - key: nvidia.com/gpu
        effect: "NoSchedule"
    limits:
      resources:
        cpu: 1000
    provider:
      launchTemplate: "karpenter-gpu-${local.cluster_name}"
      subnetSelector:
        karpenter.sh/discovery: ${local.cluster_name}
      tags:
        karpenter.sh/discovery: ${local.cluster_name}
    ttlSecondsAfterEmpty: 300
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "aws_launch_template" "gpu_shared" {
  count = var.enable_gpu && var.enable_karpenter ? 1 : 0
  name  = "karpenter-gpu-shared-${local.cluster_name}"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 300
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.karpenter[0].name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      "karpenter.sh/discovery" = local.cluster_name
      "jina.ai/node-type"      = "gpu-shared"
    }, var.tags)
  }

  image_id = data.aws_ami.eks_node_gpu.image_id

  instance_initiated_shutdown_behavior = "terminate"

  update_default_version = true

  # key_name = "${local.cluster_name}-sshkey"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  vpc_security_group_ids = [module.eks.node_security_group_id]

  user_data = base64encode(templatefile("${path.module}/customized_bootstraps.sh", { cluster_name = "${local.cluster_name}", certificate_authority = "${data.aws_eks_cluster.cluster.certificate_authority.0.data}", api_server_endpoint = "${data.aws_eks_cluster.cluster.endpoint}" }))

  tags = merge({
    "karpenter.sh/discovery" = local.cluster_name
    "jina.ai/node-type"      = "gpu-shared"
  }, var.tags)
}

resource "aws_launch_template" "gpu" {
  count = var.enable_gpu && var.enable_karpenter ? 1 : 0
  name  = "karpenter-gpu-${local.cluster_name}"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 100
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.karpenter[0].name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      "karpenter.sh/discovery" = local.cluster_name
      "jina.ai/node-type"      = "gpu"
    }, var.tags)
  }

  image_id = data.aws_ami.eks_node_gpu.image_id

  instance_initiated_shutdown_behavior = "terminate"

  update_default_version = true

  # key_name = "${local.cluster_name}-sshkey"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  vpc_security_group_ids = [module.eks.node_security_group_id]

  user_data = base64encode(templatefile("${path.module}/customized_bootstraps.sh", { cluster_name = "${local.cluster_name}", certificate_authority = "${data.aws_eks_cluster.cluster.certificate_authority.0.data}", api_server_endpoint = "${data.aws_eks_cluster.cluster.endpoint}" }))

  tags = merge({
    "karpenter.sh/discovery" = local.cluster_name
    "jina.ai/node-type"      = "gpu"
  }, var.tags)
}

resource "aws_launch_template" "karpenter" {
  count = var.enable_karpenter ? 1 : 0
  name  = "karpenter-default-${local.cluster_name}"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 120
    }
  }

  network_interfaces {
    security_groups    = [module.eks.node_security_group_id]
    device_index       = 0
    network_card_index = 0
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.karpenter[0].name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      "karpenter.sh/discovery" = local.cluster_name
      "wolf.jina.ai/node-type" = "standard"
    }, var.tags)
  }

  image_id = data.aws_ami.eks_node.image_id

  instance_initiated_shutdown_behavior = "terminate"

  update_default_version = true

  # key_name = "${local.cluster_name}-sshkey"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("${path.module}/customized_bootstraps.sh", { cluster_name = "${local.cluster_name}", certificate_authority = "${data.aws_eks_cluster.cluster.certificate_authority.0.data}", api_server_endpoint = "${data.aws_eks_cluster.cluster.endpoint}" }))

  tags = merge({
    "karpenter.sh/discovery" = local.cluster_name
    "wolf.jina.ai/node-type" = "standard"
  }, var.tags)
}

resource "aws_launch_template" "system" {
  count = var.enable_karpenter ? 1 : 0
  name  = "karpenter-system-${local.cluster_name}"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 250
    }
  }

  network_interfaces {
    security_groups    = [module.eks.node_security_group_id]
    device_index       = 0
    network_card_index = 0
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.karpenter[0].name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      "karpenter.sh/discovery" = local.cluster_name
      "wolf.jina.ai/node-type" = "system"
    }, var.tags)
  }

  image_id = data.aws_ami.eks_node.image_id

  instance_initiated_shutdown_behavior = "terminate"

  update_default_version = true

  # key_name = "${local.cluster_name}-sshkey"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("${path.module}/customized_bootstraps.sh", { cluster_name = "${local.cluster_name}", certificate_authority = "${data.aws_eks_cluster.cluster.certificate_authority.0.data}", api_server_endpoint = "${data.aws_eks_cluster.cluster.endpoint}" }))

  tags = merge({
    "karpenter.sh/discovery" = local.cluster_name
    "wolf.jina.ai/node-type" = "system"
  }, var.tags)
}
