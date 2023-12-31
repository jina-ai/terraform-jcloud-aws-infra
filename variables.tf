# Provider configurations
variable "region" {
  description = "Region of the AWS resources"
  type        = string
  default     = "us-east-1"
}

# Metadata
variable "tags" {
  description = "Tags for AWS Resource"
  type        = map(string)
  default     = {}
}

variable "app_ref" {
  description = "Suffix of Project Name of the AWS Resource"
  type        = string
  default     = ""
}


# Networking
variable "vpc_name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  type        = string
  default     = "0.0.0.0/0"
}

variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "vpc_cni_version" {
  description = "EKS VPC CNI addon version"
  type        = string
  default     = ""
}

# EKS Cluster
variable "cluster_name" {
  description = "Project Name of the AWS Resources"
  type        = string
  default     = ""
}

variable "eks_version" {
  description = "EKS version"
  type        = string
  default     = ""
}

variable "node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations"
  type        = any
  default     = {}
}

variable "create_cluster_security_group" {
  description = "Determines if a security group is created for the cluster. Note: the EKS service creates a primary security group for the cluster by default"
  type        = bool
  default     = true
}

variable "create_node_security_group" {
  description = "Determines whether to create a security group for the node groups or use the existing `node_security_group_id`"
  type        = bool
  default     = true
}

variable "node_security_group_id" {
  description = "ID of an existing security group to attach to the node groups created"
  type        = string
  default     = ""
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks"
  type        = string
  default     = null
}

# aws-auth configmap
variable "aws_auth_node_iam_role_arns_non_windows" {
  description = "List of non-Windows based node IAM role ARNs to add to the aws-auth configmap"
  type        = list(string)
  default     = []
}

variable "aws_auth_node_iam_role_arns_windows" {
  description = "List of Windows based node IAM role ARNs to add to the aws-auth configmap"
  type        = list(string)
  default     = []
}

variable "aws_auth_fargate_profile_pod_execution_role_arns" {
  description = "List of Fargate profile pod execution role ARNs to add to the aws-auth configmap"
  type        = list(string)
  default     = []
}

# KMS Key

variable "create_kms_key" {
  description = "Controls if a KMS key for cluster encryption should be created"
  type        = bool
  default     = true
}


variable "kms_key_owners" {
  description = "A list of IAM ARNs for those who will have full key permissions (`kms:*`)"
  type        = list(string)
  default     = []
}

variable "kms_key_administrators" {
  description = "A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators). If no value is provided, the current caller identity is used to ensure at least one key admin is available"
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "A list of IAM ARNs for [key users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users)"
  type        = list(string)
  default     = []
}

# Flags for components

variable "enable_alb_controller" {
  description = "Whether enable ALB controller in EKS"
  type        = bool
  default     = false
}

variable "enable_gpu" {
  description = "Whether enable GPU"
  type        = bool
  default     = false
}

variable "enable_linkerd" {
  description = "Whether to enable Linkerd"
  type        = bool
  default     = true
}

variable "enable_kong" {
  description = "Whether to enable Kong"
  type        = bool
  default     = true
}

variable "enable_knative" {
  description = "Whether to enable Knative"
  type        = bool
  default     = false
}

variable "enable_monitor_store" {
  description = "Whether enable jcloud monitor s3 store and related IAM roles"
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaler" {
  description = "Whether enable cluster autoscaler"
  type        = bool
  default     = false
}

variable "enable_monitor" {
  description = "Whether enable jcloud monitor such as Prometheus and Loki"
  type        = bool
  default     = false
}

variable "enable_external_dns" {
  description = "Whether to enable external dns"
  type        = bool
  default     = false
}

variable "external_trigger_by_events" {
  description = "Whether to enable trigger by events"
  type        = bool
  default     = true
}

variable "enable_karpenter" {
  description = "Whether to enable karpenter"
  type        = bool
  default     = false
}

variable "standard_instance_type" {
  description = "A list of EC2 instance type for stardard usage"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "t3.xlarge"]
}

variable "system_instance_type" {
  description = "A list of EC2 instance type for system usage"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "t3.xlarge"]
}

variable "shared_gpu_instance_type" {
  description = "A list of EC2 instance type for shared GPU usage"
  type        = list(string)
  default     = ["g5.xlarge", "g5.2xlarge", "g5.4xlarge"]
}

variable "gpu_instance_type" {
  description = "A list of EC2 instance type for dedicated GPU usage"
  type        = list(string)
  default     = ["g5.xlarge", "g5.2xlarge", "g5.4xlarge", "g5.12xlarge"]
}

variable "enable_ebs" {
  description = "Whether to enable ebs"
  type        = bool
  default     = false
}

variable "enable_efs" {
  description = "Whether to enable efs"
  type        = bool
  default     = false
}

variable "ebs_binding_mode" {
  description = "EBS Storage class binding mode"
  type        = string
  default     = "Immediate"
}

variable "efs_binding_mode" {
  description = "EFS Storage class binding mode"
  type        = string
  default     = "Immediate"
}

# EKS RBAC

variable "eks_admin_users" {
  description = "eks admin user"
  type        = list(string)
  default     = ["jcloud-eks-user"]
}

variable "eks_admin_roles" {
  description = "eks admin roles"
  type        = list(string)
  default     = []
}

variable "eks_readonly_users" {
  description = "eks readonly user"
  type        = list(string)
  default     = []
}

variable "eks_readonly_roles" {
  description = "eks readonly roles"
  type        = list(string)
  default     = []
}

variable "eks_custom_users" {
  description = "eks custom user"
  type        = map(string)
  default     = {}
}

variable "eks_custom_roles" {
  description = "eks custom roles"
  type        = map(string)
  default     = {}
}

# Jcloud Metrics and Logging

variable "enable_thanos" {
  description = "Whether Thanos is Enabled"
  type        = bool
  default     = false
}

variable "enable_prometheus" {
  description = "Whether Prometheus is Enabled"
  type        = bool
  default     = false
}


variable "alertmanager_config_yaml_body" {
  description = "Prometheus' Alertmanager Values in YAML Format"
  type        = string
  default     = ""
}

variable "enable_grafana" {
  description = "Whether Grafana is Enabled"
  type        = bool
  default     = false
}

variable "grafana_additional_data_sources_yaml_body" {
  description = "(Optional) Grafana Additional Data Sources List in YAML Format. If not provided, use default data sources"
  type        = string
  default     = ""
}

variable "grafana_server_domain" {
  description = "Grafana Server Domain"
  type        = string
  default     = ""
}

variable "grafana_database" {
  description = "Grafana Database Credentials"
  type        = map(string)
  default     = {
    user     = ""
    password = ""
    type     = ""
    host     = ""
  }
}

variable "grafana_admin_password" {
  description = "Grafana Admin Password"
  type        = string
  default     = ""
}

variable "grafana_ingress_tls_secret_name" {
  description = "Grafana Ingress TLS Secret Name. Ignored if grafana_ingress_yaml_body is set"
  type        = string
  default     = ""
}

variable "grafana_ingress_class_name" {
  description = "Grafana Ingress Class Name. Ignored if grafana_ingress_yaml_body is set."
  type        = string
  default     = "kong"
}

variable "grafana_ingress_yaml_body" {
  description = "Grafana Ingress Values in YAML Format. This overwrites grafana_ingress_tls_secret_name and grafana_ingress_class_name"
  type        = string
  default     = ""
}

variable "thanos_object_storage_config_name" {
  description = "Thanos object storage name"
  type        = string
  default     = "jcloud-monitor-store"
}

variable "thanos_object_storage_config_key" {
  description = "Thanos object storage name"
  type        = string
  default     = "objstore.yml"
}

variable "prometheus_otlp_collector_scrape_endpoint" {
  description = "OTLP Collector Scrape Endpoint"
  default     = "kube-otlp-collector-opentelemetry-collector.monitor.svc.cluster.local:8888"
}


variable "prometheus_stack_overwrite_values_yaml_body" {
  description = "Overwrite Prometheus-Stack Values in YAML. Please refer to https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml for all possible values you can set."
  type        = string
  default     = ""
}

variable "promtail_overwrite_values_yaml_body" {
  description = "Overwrite Promtail Values in YAML"
  default     = ""
}

variable "promtail_clients_urls" {
  description = "Promtail's Clients' URLS to push logs to"
  type        = list(string)
  default     = ["http://kube-loki.monitor.svc.cluster.local:3100/loki/api/v1/push"]
}

variable "enable_promtail" {
  description = "Whether Promtail is enabled"
  type        = bool
  default     = false
}

variable "enable_loki" {
  description = "Whether Loki is enabled"
  type        = bool
  default     = false
}

variable "loki_overwrite_values_yaml_body" {
  description = "Overwrite Loki Values in YAML. Please refer to https://github.com/grafana/loki/blob/main/production/helm/loki/values.yaml for all possible values you can set."
  default     = ""
}

variable "enable_tempo" {
  description = "Whether to enable Tempo for tracing"
  type        = bool
  default     = false
}

variable "tempo_overwrite_values_yaml_body" {
  description = "Overwrite Tempo Values in YAML. Please refer to https://github.com/grafana/helm-charts/blob/main/charts/tempo-distributed/values.yaml for all possible values you can set."
  default     = ""
}

variable "enable_otlp_collector" {
  description = "Whether to enable OTLP Collector"
  type        = bool
  default     = false
}

variable "otlp_endpoint" {
  description = "OTLP Endpoint"
  default     = "kube-tempo-distributor:4317"
}

variable "otlp_collector_overwrite_values_yaml_body" {
  description = "Overwrite OTLP Collector Values in YAML"
  default     = ""
}

variable "thanos_overwrite_values_yaml_body" {
  description = "Thanos Overwrite Values in YAML"
  default     = ""
}

variable "create_buckets" {
  description = "Jcloud monitor bucket"
  type        = bool
  default     = true
}

variable "metrics_bucket" {
  description = "Jcloud metrics bucket name"
  type        = string
  default     = ""
}

variable "log_bucket" {
  description = "Jcloud log bucket name"
  type        = string
  default     = ""
}

variable "traces_bucket" {
  description = "Jcloud traces bucket name"
  type        = string
  default     = ""
}

variable "log_bucket_region" {
  description = "Log Bucket Region"
  default     = ""
}

variable "traces_bucket_region" {
  description = "Traces S3 Bucket Region"
  default     = ""
}

variable "metrics_bucket_region" {
  description = "Metrics S3 Bucket Region"
  default     = ""
}

variable "monitor_iam_access_key_id" {
  description = "Monitor IAM Access Key ID"
  default     = ""
}

variable "monitor_iam_access_key_secret" {
  description = "Monitor IAM Access Key Secret"
  default     = ""
}

variable "enable_metrics" {
  description = "If set to true, Prometheus, Thanos and DCGM Exporter will be enabled, and corresponding toggles (i.e enable_prometheus, enable_thanos, enable_dcgm_exporter) will be overwritten"
  default     = false
}

variable "enable_logging" {
  description = "If set to true, Loki and Promtail will be enabled, and corresponding toggles (i.e. enable_loki, enable_promtail) will be overwritten"
  default     = false
}

variable "enable_tracing" {
  description = "If set to true, Tempo and OTLP Collector will be enabled, and corresponding toggles (i.e enable_tempo, enable_otlp_collector) will be overwritten"
  default     = false
}

variable "enable_dcgm_exporter" {
  description = "Whether to enable DCGM Exporter"
  default     = false
}

# Other
variable "init_node_type" {
  description = "A list of EC2 instance type for init node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "domain_filters" {
  description = "The domain filters for external dns"
  type        = string
  default     = "{wolf.jina.ai,dev.jina.ai,docsqa.jina.ai}"
}

variable "karpenter_consolidation_enable" {
  description = "Whether to enable consolidation on Karpenter"
  type        = bool
  default     = false
}

variable "remote_external_dns_role" {
  description = "Remote AWS external DNS role"
  type        = string
  default     = ""
}

variable "external_dns_role" {
  description = "External AWS external DNS role"
  type        = string
  default     = ""
}

variable "shared_gpu_slicing_replicas" {
  description = "Shared GPU slice number"
  type        = number
  default     = 3
}

variable "shared_gpu_node_labels" {
  description = "Karpenter accelerator type for shared GPU"
  type        = map(any)
  default     = {}
}

variable "gpu_node_labels" {
  description = "Karpenter accelerator type for GPU"
  type        = map(any)
  default     = {}
}

# Cert manager

variable "certs" {
  description = "JCloud ingress certs"
  type        = list(map(string))
  default     = []
}

variable "enable_cert_manager" {
  description = "Whether create cert manager role for service account"
  type        = bool
  default     = true
}

variable "remote_cert_manager_role" {
  description = "Remote cert manager role"
  type        = string
  default     = ""
}

# Kubecost
variable "enable_kubecost" {
  description = "Whether to enable Kubecost"
  type        = bool
  default     = false
}

variable "create_kubecost_metrics_buckets" {
  description = "Whether to Create Kubecost metrics bucket"
  type        = bool
  default     = false
}

variable "kubecost_metric_buckets" {
  description = "Kubecost metrics bucket"
  type        = string
  default     = ""
}

variable "kubecost_s3_region" {
  description = "Kubecost metrics bucket region"
  type        = string
  default     = "us-east-1"
}

variable "kubecost_athena_region" {
  description = "Kubecost athena bucket region"
  type        = string
  default     = "us-east-1"
}

variable "kubecost_athena_bucket" {
  description = "Kubecost athena bucket url"
  type        = string
  default     = ""
}

variable "kubecost_grafana_host" {
  description = "Kubecost grafana host"
  type        = string
  default     = ""
}

variable "kubecost_master" {
  description = "Whethere is kubecost master"
  type        = bool
  default     = true
}
