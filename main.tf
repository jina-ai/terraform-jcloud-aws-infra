################################################################################
# AMI data
################################################################################

data "aws_ami" "eks_node" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.eks_version}*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_eks_cluster" "cluster" {
  name       = local.cluster_name
  depends_on = [module.eks.cluster_id, module.eks.cluster_endpoint]
}

data "aws_eks_cluster_auth" "auth" {
  name       = local.cluster_name
  depends_on = [module.eks.cluster_id, module.eks.cluster_endpoint]
}


data "aws_ami" "eks_node_gpu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-gpu-node-${var.eks_version}*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# Local Variables
################################################################################

locals {
  cluster_name = var.cluster_name
  app_ref      = try(var.app_ref, element(split("-", var.cluster_name), 3), var.cluster_name)
  partition    = data.aws_partition.current.partition
  account_id   = data.aws_caller_identity.current.account_id
  vpc_name     = var.vpc_name
  vpc_regions  = "[${join(", ", var.azs)}]"
  region       = try(var.region, data.aws_region.current.name)
  init_nodegroup = {
    inital = {
      instance_types = var.init_node_type
      # We don't need the node security group since we are using the
      # cluster-created security group, which Karpenter will also use
      create_security_group                 = false
      attach_cluster_primary_security_group = false

      min_size     = 1
      max_size     = 3
      desired_size = 2


      iam_role_additional_policies = {
        # Required by Karpenter
        KarpenterAmazonSSMManagedInstanceCore = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
        KarpenterCloudWatchAgentServerPolicy  = "arn:${local.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
      }

      bootstrap_extra_args = "--max-pods=110 --system-reserved cpu=300m,memory=0.5Gi,ephemeral-storage=1Gi --eviction-hard memory.available<200Mi,nodefs.available<10% --image-gc-high-threshold=80 --image-gc-low-threshold=60"

      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      cat <<-EOF > /etc/profile.d/bootstrap.sh
      export CONTAINER_RUNTIME="containerd"
      EOF
      # Source extra environment variables in bootstrap script
      sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
      EOT

      force_update_version = true
      labels = {
        "jina.ai/node-type" = "system"
      }
    }
  }
}


################################################################################
# k8s Module
################################################################################

module "eks" {
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
  source  = "terraform-aws-modules/eks/aws"
  version = "19.19.0"

  cluster_name                    = local.cluster_name
  cluster_version                 = var.eks_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cloudwatch_log_group_retention_in_days = 3

  # Required for Karpenter role below
  enable_irsa = true

  create_cluster_security_group = var.create_cluster_security_group
  create_node_security_group    = var.create_node_security_group

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_linderd_tcp = {
      description                   = "Control plane invoke Linkerd Tap"
      protocol                      = "tcp"
      from_port                     = 8089
      to_port                       = 8089
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  cluster_addons = {
    coredns = {
      preserve                    = true
      most_recent                 = true
      resolve_conflicts           = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    }
    kube-proxy = {
      most_recent                 = true
      resolve_conflicts           = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    }
    vpc-cni = {
      most_recent                 = "${var.vpc_cni_version}" == "" ? true : false
      addon_version               = "${var.vpc_cni_version}" == "" ? "" : "${var.vpc_cni_version}"
      most_recent                 = true
      resolve_conflicts           = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
      configuration_values = jsonencode({
        env = {
          WARM_PREFIX_TARGET       = "1",
          WARM_IP_TARGET           = "5",
          MINIMUM_IP_TARGET        = "2",
          ENABLE_PREFIX_DELEGATION = "true"
        }
      })
    }
  }

  cluster_iam_role_dns_suffix = "amazonaws.com"

  create_kms_key = var.create_kms_key
  cluster_encryption_config = {
    resources = ["secrets"]
  }
  kms_key_owners         = var.kms_key_owners
  kms_key_administrators = var.kms_key_administrators
  kms_key_users          = var.kms_key_users

  # Only need one node to get Karpenter up and running.
  # This ensures core services such as VPC CNI, CoreDNS, etc. are up and running
  # so that Karpetner can be deployed and start managing compute capacity as required
  eks_managed_node_groups = local.init_nodegroup

  cluster_service_ipv4_cidr = var.cluster_service_ipv4_cidr

  # aws-auth configmap
  manage_aws_auth_configmap = true
  create_aws_auth_configmap = false

  aws_auth_roles = concat(
    [for role in var.eks_admin_roles :
      {
        rolearn  = startswith(role, "arn:aws:iam") == true ? role : "arn:aws:iam::${local.account_id}:role/${role}"
        username = startswith(role, "arn:aws:iam") == true ? split("/", role)[1] : role
        groups   = ["system:masters"]
      }
    ],
    [for role in var.eks_readonly_roles :
      {
        rolearn  = startswith(role, "arn:aws:iam") == true ? role : "arn:aws:iam::${local.account_id}:role/${role}"
        username = startswith(role, "arn:aws:iam") == true ? split("/", role)[1] : role
        groups   = ["wolf-read-only"]
      }
    ],
    [for role, group in var.eks_custom_roles :
      {
        rolearn  = startswith(role, "arn:aws:iam") == true ? role : "arn:aws:iam::${local.account_id}:role/${role}"
        username = startswith(role, "arn:aws:iam") == true ? split("/", role)[1] : role
        groups   = ["${group}"]
      }
    ],
  )

  aws_auth_users = concat(
    [for user in var.eks_admin_users :
      {
        userarn  = startswith(user, "arn:aws:iam") == true ? user : "arn:aws:iam::${local.account_id}:user/${user}"
        username = startswith(user, "arn:aws:iam") == true ? split("/", user)[1] : user
        groups   = ["system:masters"]
      }
    ],
    [for user in var.eks_readonly_users :
      {
        userarn  = startswith(user, "arn:aws:iam") == true ? user : "arn:aws:iam::${local.account_id}:user/${user}"
        username = startswith(user, "arn:aws:iam") == true ? split("/", user)[1] : user
        groups   = ["wolf-read-only"]
      }
    ],
    [for user, group in var.eks_custom_users :
      {
        userarn  = startswith(user, "arn:aws:iam") == true ? user : "arn:aws:iam::${local.account_id}:user/${user}"
        username = startswith(user, "arn:aws:iam") == true ? split("/", user)[1] : user
        groups   = ["${group}"]
      }
    ],
  )

  tags = var.tags
}

# Configured knative internal domain to coredns
resource "kubernetes_config_map_v1_data" "coredns-domain" {
  count = var.enable_knative ? 1 : 0
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
  data = {
    "Corefile" = <<YAML
.:53 {
      errors
      health {
          lameduck 5s
        }
      ready
      rewrite name regex (^.*).svc.wolf.internal kong-proxy.kong.svc.cluster.local
      kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
      }
      prometheus :9153
      forward . /etc/resolv.conf
      cache 30
      loop
      reload
      loadbalance
  }
YAML
  }
  force      = true
  depends_on = [module.eks]
}


resource "time_sleep" "this" {
  create_duration = "60s"

  triggers = {
    cluster_name                       = module.eks.cluster_name
    cluster_endpoint                   = module.eks.cluster_endpoint
    cluster_version                    = module.eks.cluster_version
    cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  }
  depends_on = [module.eks.eks_managed_node_groups]
}

################################################################################
# Supporting Resources
################################################################################

module "eks-ebs-csi" {
  count      = var.enable_ebs ? 1 : 0
  depends_on = [module.eks]
  source     = "./modules/aws/k8s-ebs-csi"

  cluster_name               = local.cluster_name
  binding_mode               = var.ebs_binding_mode != "" ? var.ebs_binding_mode : "Immediate"
  endpoint                   = module.eks.cluster_endpoint
  certificate_authority_data = module.eks.cluster_certificate_authority_data
}

module "eks-efs-csi" {
  count      = var.enable_efs ? 1 : 0
  depends_on = [module.eks]
  source     = "./modules/aws/k8s-efs-csi"

  cluster_name               = local.cluster_name
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.private_subnets
  allow_cidr                 = var.cidr
  oidc_provider_arn          = module.eks.oidc_provider_arn
  region                     = local.region
  create_efs                 = true
  endpoint                   = module.eks.cluster_endpoint
  binding_mode               = var.efs_binding_mode != "" ? var.efs_binding_mode : "Immediate"
  certificate_authority_data = module.eks.cluster_certificate_authority_data
}

module "autoscaler" {
  count             = var.enable_cluster_autoscaler ? 1 : 0
  source            = "./modules/aws/cluster-autoscaler"
  cluster_region    = var.region
  cluster_name      = time_sleep.this.triggers["cluster_name"]
  oidc_provider_arn = module.eks.oidc_provider_arn
  namespace         = "wolf"
}

module "alb-controller" {
  count  = var.enable_alb_controller ? 1 : 0
  source = "./modules/aws/alb-controller"

  cluster_name      = local.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  depends_on        = [module.eks]
}

module "external-dns" {
  count  = var.enable_external_dns ? 1 : 0
  source = "./modules/general/external-dns"

  cluster_name      = time_sleep.this.triggers["cluster_name"]
  domain_filters    = var.domain_filters
  app_ref           = local.app_ref
  oidc_provider_arn = module.eks.oidc_provider_arn
  remote_role       = var.remote_external_dns_role
  external_dns_role = var.external_dns_role
  trigger_by_events = var.external_trigger_by_events
}

module "linkerd" {
  count      = var.enable_linkerd ? 1 : 0
  source     = "./modules/general/linkerd"
  depends_on = [module.eks.eks_managed_node_groups]
}

module "kong" {
  count            = var.enable_kong ? 1 : 0
  source           = "./modules/general/kong"
  cluster_endpoint = time_sleep.this.triggers["cluster_endpoint"]
}

module "nvidia_plugin" {
  count  = var.enable_gpu ? 1 : 0
  source = "./modules/nvidia"

  node_selector = {
    "jina.ai/gpu-type" = "nvidia"
  }
  slicing_replicas = var.shared_gpu_slicing_replicas
  depends_on       = [module.eks]
}

module "cert_manager" {
  count  = var.enable_cert_manager ? 1 : 0
  source = "./modules/general/cert-manager"

  cluster_name             = time_sleep.this.triggers["cluster_name"]
  oidc_provider_arn        = module.eks.oidc_provider_arn
  remote_cert_manager_role = var.remote_cert_manager_role
  certs                    = var.certs
}

module "knative" {
  count            = var.enable_knative ? 1 : 0
  source           = "./modules/general/knative"
  cluster_endpoint = time_sleep.this.triggers["cluster_endpoint"]
}

module "monitor" {
  count  = var.enable_monitor ? 1 : 0
  source = "./modules/general/monitor"
  # common variables
  cluster_name   = time_sleep.this.triggers["cluster_name"]
  enable_logging = var.enable_logging
  enable_metrics = var.enable_metrics
  enable_tracing = var.enable_tracing
  # prometheus
  enable_prometheus                           = var.enable_prometheus
  enable_grafana                              = var.enable_grafana
  grafana_server_domain                       = var.grafana_server_domain
  grafana_database                            = var.grafana_database
  grafana_admin_password                      = var.grafana_admin_password
  grafana_ingress_tls_secret_name             = var.grafana_ingress_tls_secret_name
  grafana_ingress_class_name                  = var.grafana_ingress_class_name
  grafana_additional_data_sources_yaml_body   = var.grafana_additional_data_sources_yaml_body
  alertmanager_config_yaml_body               = var.alertmanager_config_yaml_body
  grafana_ingress_yaml_body                   = var.grafana_ingress_yaml_body
  prometheus_otlp_collector_scrape_endpoint   = var.prometheus_otlp_collector_scrape_endpoint
  prometheus_stack_overwrite_values_yaml_body = var.prometheus_stack_overwrite_values_yaml_body
  # promtail
  enable_promtail                     = var.enable_promtail
  promtail_clients_urls               = var.promtail_clients_urls
  promtail_overwrite_values_yaml_body = var.promtail_overwrite_values_yaml_body
  # loki
  enable_loki                     = var.enable_loki
  loki_overwrite_values_yaml_body = var.loki_overwrite_values_yaml_body
  # tempo
  enable_tempo                     = var.enable_tempo
  tempo_overwrite_values_yaml_body = var.tempo_overwrite_values_yaml_body
  # otlp collector 
  enable_otlp_collector                     = var.enable_otlp_collector
  otlp_endpoint                             = var.otlp_endpoint
  otlp_collector_overwrite_values_yaml_body = var.otlp_collector_overwrite_values_yaml_body
  # thanos
  enable_thanos                     = var.enable_thanos
  thanos_object_storage_config_name = var.thanos_object_storage_config_name # also required by prometheus module
  thanos_object_storage_config_key  = var.thanos_object_storage_config_key  # also required by prometheus module
  thanos_overwrite_values_yaml_body = var.thanos_overwrite_values_yaml_body
  # monitor store component arguments
  enable_monitor_store = var.enable_monitor_store
  create_buckets       = var.create_buckets
  traces_bucket        = var.traces_bucket
  metrics_bucket       = var.metrics_bucket
  log_bucket           = var.log_bucket
  tags                 = var.tags
  enable_dcgm_exporter = var.enable_dcgm_exporter
  # in case monitor_store is not enabled, we need the following to access custom aws buckets for logs, metrics and etc
  log_bucket_region             = var.log_bucket_region
  traces_bucket_region          = var.traces_bucket_region
  metrics_bucket_region         = var.metrics_bucket_region
  monitor_iam_access_key_id     = var.monitor_iam_access_key_id
  monitor_iam_access_key_secret = var.monitor_iam_access_key_secret
  # instantiate after eks is provisioned
  depends_on = [module.eks]
}

module "kubecost" {
  count                   = var.enable_kubecost ? 1 : 0
  source                  = "./modules/general/kubecost"
  cluster_name            = var.cluster_name
  create_metrics_buckets  = var.create_kubecost_metrics_buckets
  kubecost_metric_buckets = var.kubecost_metric_buckets
  s3_region               = var.kubecost_s3_region
  athena_region           = var.kubecost_athena_region
  athena_bucket           = var.kubecost_athena_bucket
  grafana_host            = var.kubecost_grafana_host
  master                  = var.kubecost_master
  wait_for_write          = module.eks.cluster_endpoint
  tags                    = merge({ "Name" : "${module.eks.cluster_endpoint}-0" }, var.tags)
  depends_on              = [module.eks]
}

resource "helm_release" "metrics_server" {
  namespace = "kube-system"

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  depends_on = [module.eks]
}

data "kubectl_file_documents" "wolf" {
  content = file("${path.module}/wolf.yaml")
}

resource "kubectl_manifest" "wolf_resources" {
  count      = length(data.kubectl_file_documents.wolf.documents)
  yaml_body  = element(data.kubectl_file_documents.wolf.documents, count.index)
  depends_on = [module.eks]
}
