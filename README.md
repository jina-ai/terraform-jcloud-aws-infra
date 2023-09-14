# Terraform-JCloud-AWS-Infra

Terraform module which creates JCloud infra resource running on AWS based on EKS (Kubernetes) resources

#### Infrastructure:
The module includes below infrastructure and sub modules to support various JCloud features:
- **infrastructures**:
  - EKS
  - VPC
- **components**:
    - [EBS-CSI](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
    - [EFS-CSI](https://github.com/kubernetes-sigs/aws-efs-csi-driver)
    - [Karpenter](https://karpenter.sh/)
    - [Knativer](https://knative.dev/docs/)
    - [Kong](https://konghq.com/)
    - [external-dns](https://github.com/kubernetes-sigs/external-dns)
    - [cert-manager](https://cert-manager.io/)
    - [linkerd](https://linkerd.io/)

The examples provided under `examples/` provide a set of configurations that demonstrate different configurations and settings that can be used with this module. However, these examples are not representative production cluster. 

#### Components:
  Components refers the Kubernetes tools or software that support JCloud features.
  - Knative (support application autoscale)
  - Kong (Ingress gateway)
  - Linkerd (Service Mesh)
  - External-dns (External DNS registration)
  - Karpenter (node autoscale) 

### Usage
```
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

################################################################################
# k8s Module
################################################################################

module "jcloud" {
  source = "jina-ai/aws-infra/jcloud"
  version = "0.0.1"

  region       = "us-east-1"
  cluster_name = "jcloud-dev"

  vpc_name    = "jcloud-dev-vpc"
  eks_version = "1.27"

  cidr            = "10.200.0.0/20"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.200.6.0/24", "10.200.7.0/24", "10.200.8.0/24"]
  private_subnets = ["10.200.0.0/23", "10.200.2.0/23", "10.200.4.0/23"]

  kms_key_owners = [data.aws_caller_identity.current.arn]

  eks_admin_users = [data.aws_caller_identity.current.arn]

  enable_cert_manager = false
  enable_kong         = true
  enable_linkerd      = true

  tags = var.tags
}

```

## Examples

- [Minimal](https://github.com/jina-ai/terraform-jcloud-aws-infra/tree/master/examples/minimal): JCloud cluster only with ingress controller.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.47 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.1.2 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.47 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.4 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.14 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb-controller"></a> [alb-controller](#module\_alb-controller) | ./modules/aws/alb-controller | n/a |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | ./modules/general/cert-manager | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 19.16.0 |
| <a name="module_eks-ebs-csi"></a> [eks-ebs-csi](#module\_eks-ebs-csi) | ./modules/aws/k8s-ebs-csi | n/a |
| <a name="module_eks-efs-csi"></a> [eks-efs-csi](#module\_eks-efs-csi) | ./modules/aws/k8s-efs-csi | n/a |
| <a name="module_external-dns"></a> [external-dns](#module\_external-dns) | ./modules/general/external-dns | n/a |
| <a name="module_karpenter_irsa"></a> [karpenter\_irsa](#module\_karpenter\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.2.0 |
| <a name="module_knative"></a> [knative](#module\_knative) | ./modules/general/knative | n/a |
| <a name="module_kong"></a> [kong](#module\_kong) | ./modules/general/kong | n/a |
| <a name="module_kubecost"></a> [kubecost](#module\_kubecost) | ./modules/general/kubecost | n/a |
| <a name="module_linkerd"></a> [linkerd](#module\_linkerd) | ./modules/general/linkerd | n/a |
| <a name="module_monitor"></a> [monitor](#module\_monitor) | ./modules/general/monitor | n/a |
| <a name="module_nvidia_plugin"></a> [nvidia\_plugin](#module\_nvidia\_plugin) | ./modules/nvidia | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 4.0 |
| <a name="module_vpc_endpoint_security_group"></a> [vpc\_endpoint\_security\_group](#module\_vpc\_endpoint\_security\_group) | terraform-aws-modules/security-group/aws | ~> 4.0 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_launch_template.gpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_launch_template.gpu_shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_launch_template.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_launch_template.system](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.metrics_server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.karpenter_provisioner](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_provisioner_gpu](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_provisioner_gpu_shared](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_provisioner_privileged](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_provisioner_system](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.wolf_resources](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_config_map_v1_data.coredns-domain](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [time_sleep.this](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_ami.eks_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.eks_node_gpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [kubectl_file_documents.wolf](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_ref"></a> [app\_ref](#input\_app\_ref) | Suffix of Project Name of the AWS Resource | `string` | `""` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | A list of availability zones in the region | `list(string)` | `[]` | no |
| <a name="input_certs"></a> [certs](#input\_certs) | JCloud ingress certs | `list(map(string))` | `[]` | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden | `string` | `"0.0.0.0/0"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Project Name of the AWS Resources | `string` | `""` | no |
| <a name="input_create_buckets"></a> [create\_buckets](#input\_create\_buckets) | Jcloud monitor bucket | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Controls if a KMS key for cluster encryption should be created | `bool` | `true` | no |
| <a name="input_create_kubecost_metrics_buckets"></a> [create\_kubecost\_metrics\_buckets](#input\_create\_kubecost\_metrics\_buckets) | Whether to Create Kubecost metrics bucket | `bool` | `false` | no |
| <a name="input_domain_filters"></a> [domain\_filters](#input\_domain\_filters) | The domain filters for external dns | `string` | `"{wolf.jina.ai,dev.jina.ai,docsqa.jina.ai}"` | no |
| <a name="input_ebs_binding_mode"></a> [ebs\_binding\_mode](#input\_ebs\_binding\_mode) | EBS Storage class binding mode | `string` | `"Immediate"` | no |
| <a name="input_efs_binding_mode"></a> [efs\_binding\_mode](#input\_efs\_binding\_mode) | EFS Storage class binding mode | `string` | `"Immediate"` | no |
| <a name="input_eks_admin_roles"></a> [eks\_admin\_roles](#input\_eks\_admin\_roles) | eks admin roles | `list(string)` | `[]` | no |
| <a name="input_eks_admin_users"></a> [eks\_admin\_users](#input\_eks\_admin\_users) | eks admin user | `list(string)` | <pre>[<br>  "jcloud-eks-user"<br>]</pre> | no |
| <a name="input_eks_custom_roles"></a> [eks\_custom\_roles](#input\_eks\_custom\_roles) | eks custom roles | `map(string)` | `{}` | no |
| <a name="input_eks_custom_users"></a> [eks\_custom\_users](#input\_eks\_custom\_users) | eks custom user | `map(string)` | `{}` | no |
| <a name="input_eks_readonly_roles"></a> [eks\_readonly\_roles](#input\_eks\_readonly\_roles) | eks readonly roles | `list(string)` | `[]` | no |
| <a name="input_eks_readonly_users"></a> [eks\_readonly\_users](#input\_eks\_readonly\_users) | eks readonly user | `list(string)` | `[]` | no |
| <a name="input_eks_version"></a> [eks\_version](#input\_eks\_version) | EKS version | `string` | `""` | no |
| <a name="input_enable_alb_controller"></a> [enable\_alb\_controller](#input\_enable\_alb\_controller) | Whether enable ALB controller in EKS | `bool` | `false` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | Whether create cert manager role for service account | `bool` | `true` | no |
| <a name="input_enable_ebs"></a> [enable\_ebs](#input\_enable\_ebs) | Whether to enable ebs | `bool` | `false` | no |
| <a name="input_enable_efs"></a> [enable\_efs](#input\_enable\_efs) | Whether to enable efs | `bool` | `false` | no |
| <a name="input_enable_external_dns"></a> [enable\_external\_dns](#input\_enable\_external\_dns) | Whether to enable external dns | `bool` | `false` | no |
| <a name="input_enable_gpu"></a> [enable\_gpu](#input\_enable\_gpu) | Whether enable GPU | `bool` | `false` | no |
| <a name="input_enable_karpenter"></a> [enable\_karpenter](#input\_enable\_karpenter) | Whether to enable karpenter | `bool` | `false` | no |
| <a name="input_enable_knative"></a> [enable\_knative](#input\_enable\_knative) | Whether to enable Knative | `bool` | `false` | no |
| <a name="input_enable_kong"></a> [enable\_kong](#input\_enable\_kong) | Whether to enable Kong | `bool` | `true` | no |
| <a name="input_enable_kubecost"></a> [enable\_kubecost](#input\_enable\_kubecost) | Whether to enable Kubecost | `bool` | `false` | no |
| <a name="input_enable_linkerd"></a> [enable\_linkerd](#input\_enable\_linkerd) | Whether to enable Linkerd | `bool` | `true` | no |
| <a name="input_enable_monitor_store"></a> [enable\_monitor\_store](#input\_enable\_monitor\_store) | Whether enable jcloud monitor s3 store and related IAM roles | `bool` | `false` | no |
| <a name="input_gpu_instance_type"></a> [gpu\_instance\_type](#input\_gpu\_instance\_type) | A list of EC2 instance type for dedicated GPU usage | `list(string)` | <pre>[<br>  "g5.xlarge",<br>  "g5.2xlarge",<br>  "g5.4xlarge",<br>  "g5.12xlarge"<br>]</pre> | no |
| <a name="input_init_node_type"></a> [init\_node\_type](#input\_init\_node\_type) | A list of EC2 instance type for init node group | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
| <a name="input_karpenter_consolidation_enable"></a> [karpenter\_consolidation\_enable](#input\_karpenter\_consolidation\_enable) | Whether to enable consolidation on Karpenter | `bool` | `false` | no |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators). If no value is provided, the current caller identity is used to ensure at least one key admin is available | `list(string)` | `[]` | no |
| <a name="input_kms_key_owners"></a> [kms\_key\_owners](#input\_kms\_key\_owners) | A list of IAM ARNs for those who will have full key permissions (`kms:*`) | `list(string)` | `[]` | no |
| <a name="input_kms_key_users"></a> [kms\_key\_users](#input\_kms\_key\_users) | A list of IAM ARNs for [key users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users) | `list(string)` | `[]` | no |
| <a name="input_kubecost_athena_bucket"></a> [kubecost\_athena\_bucket](#input\_kubecost\_athena\_bucket) | Kubecost athena bucket url | `string` | `""` | no |
| <a name="input_kubecost_athena_region"></a> [kubecost\_athena\_region](#input\_kubecost\_athena\_region) | Kubecost athena bucket region | `string` | `"us-east-1"` | no |
| <a name="input_kubecost_grafana_host"></a> [kubecost\_grafana\_host](#input\_kubecost\_grafana\_host) | Kubecost grafana host | `string` | `""` | no |
| <a name="input_kubecost_master"></a> [kubecost\_master](#input\_kubecost\_master) | Whethere is kubecost master | `bool` | `true` | no |
| <a name="input_kubecost_metric_buckets"></a> [kubecost\_metric\_buckets](#input\_kubecost\_metric\_buckets) | Kubecost metrics bucket | `string` | `""` | no |
| <a name="input_kubecost_s3_region"></a> [kubecost\_s3\_region](#input\_kubecost\_s3\_region) | Kubecost metrics bucket region | `string` | `"us-east-1"` | no |
| <a name="input_log_bucket"></a> [log\_bucket](#input\_log\_bucket) | Jcloud log bucket name | `string` | `""` | no |
| <a name="input_metrics_bucket"></a> [metrics\_bucket](#input\_metrics\_bucket) | Jcloud metrics bucket name | `string` | `""` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | A list of private subnets inside the VPC | `list(string)` | `[]` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnets inside the VPC | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | Region of the AWS resources | `string` | `"us-east-1"` | no |
| <a name="input_remote_cert_manager_role"></a> [remote\_cert\_manager\_role](#input\_remote\_cert\_manager\_role) | Remote cert manager role | `string` | `""` | no |
| <a name="input_remote_external_dns_role"></a> [remote\_external\_dns\_role](#input\_remote\_external\_dns\_role) | Remote AWS external DNS role | `string` | `""` | no |
| <a name="input_shared_gpu_instance_type"></a> [shared\_gpu\_instance\_type](#input\_shared\_gpu\_instance\_type) | A list of EC2 instance type for shared GPU usage | `list(string)` | <pre>[<br>  "g5.xlarge",<br>  "g5.2xlarge",<br>  "g5.4xlarge"<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for AWS Resource | `map(string)` | `{}` | no |
| <a name="input_traces_bucket"></a> [traces\_bucket](#input\_traces\_bucket) | Jcloud traces bucket name | `string` | `""` | no |
| <a name="input_vpc_cni_version"></a> [vpc\_cni\_version](#input\_vpc\_cni\_version) | EKS VPC CNI addon version | `string` | `""` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name to be used on all the resources as identifier | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_auth_configmap_yaml"></a> [aws\_auth\_configmap\_yaml](#output\_aws\_auth\_configmap\_yaml) | [DEPRECATED - use `var.manage_aws_auth_configmap`] Formatted yaml output for base aws-auth configmap containing roles used in cluster node groups/fargate profiles |
| <a name="output_azs"></a> [azs](#output\_azs) | A list of availability zones specified as argument to this module |
| <a name="output_cert_manager_irsa_arn"></a> [cert\_manager\_irsa\_arn](#output\_cert\_manager\_irsa\_arn) | cert manager service account IAM Role ARN |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | Arn of cloudwatch log group created |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of cloudwatch log group created |
| <a name="output_cluster_addons"></a> [cluster\_addons](#output\_cluster\_addons) | Map of attribute maps for all EKS cluster addons enabled |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The Amazon Resource Name (ARN) of the cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for your Kubernetes API server |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN of the EKS cluster |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | IAM role name of the EKS cluster |
| <a name="output_cluster_iam_role_unique_id"></a> [cluster\_iam\_role\_unique\_id](#output\_cluster\_iam\_role\_unique\_id) | Stable and unique string identifying the IAM role |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready |
| <a name="output_cluster_identity_providers"></a> [cluster\_identity\_providers](#output\_cluster\_identity\_providers) | Map of attribute maps for all EKS identity providers enabled |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the cluster |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider |
| <a name="output_cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | Platform version for the cluster |
| <a name="output_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#output\_cluster\_primary\_security\_group\_id) | Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console |
| <a name="output_cluster_security_group_arn"></a> [cluster\_security\_group\_arn](#output\_cluster\_security\_group\_arn) | Amazon Resource Name (ARN) of the cluster security group |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | ID of the cluster security group |
| <a name="output_cluster_status"></a> [cluster\_status](#output\_cluster\_status) | Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED` |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | The Kubernetes version for the cluster |
| <a name="output_efs_dns_name"></a> [efs\_dns\_name](#output\_efs\_dns\_name) | The DNS name for the filesystem |
| <a name="output_efs_id"></a> [efs\_id](#output\_efs\_id) | The ID that identifies the file system (e.g., fs-ccfc0d65). |
| <a name="output_efs_irsa_arn"></a> [efs\_irsa\_arn](#output\_efs\_irsa\_arn) | efs service account IAM Role ARN |
| <a name="output_monitor_iam_access_key_id"></a> [monitor\_iam\_access\_key\_id](#output\_monitor\_iam\_access\_key\_id) | The access key ID |
| <a name="output_monitor_iam_access_key_secret"></a> [monitor\_iam\_access\_key\_secret](#output\_monitor\_iam\_access\_key\_secret) | The access key secret |
| <a name="output_monitor_iam_role_arn"></a> [monitor\_iam\_role\_arn](#output\_monitor\_iam\_role\_arn) | ARN of IAM role |
| <a name="output_monitor_iam_role_name"></a> [monitor\_iam\_role\_name](#output\_monitor\_iam\_role\_name) | Name of IAM role |
| <a name="output_monitor_iam_user_arn"></a> [monitor\_iam\_user\_arn](#output\_monitor\_iam\_user\_arn) | The ARN assigned by AWS for this user |
| <a name="output_monitor_iam_user_name"></a> [monitor\_iam\_user\_name](#output\_monitor\_iam\_user\_name) | The user's name |
| <a name="output_mount_target_dns_name"></a> [mount\_target\_dns\_name](#output\_mount\_target\_dns\_name) | The DNS name for the given subnet/AZ |
| <a name="output_node_security_group_arn"></a> [node\_security\_group\_arn](#output\_node\_security\_group\_arn) | Amazon Resource Name (ARN) of the node shared security group |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | ID of the node shared security group |
| <a name="output_oidc_provider"></a> [oidc\_provider](#output\_oidc\_provider) | The OpenID Connect identity provider (issuer URL without leading `https://`) |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | The ARN of the OIDC Provider if `enable_irsa = true` |
| <a name="output_private_subnet_arns"></a> [private\_subnet\_arns](#output\_private\_subnet\_arns) | List of ARNs of private subnets |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_public_subnet_arns"></a> [public\_subnet\_arns](#output\_public\_subnet\_arns) | List of ARNs of public subnets |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets |
| <a name="output_region"></a> [region](#output\_region) | Region of the AWS resources |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | The ARN of the VPC |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
<!-- END_TF_DOCS -->