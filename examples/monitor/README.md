# Monitor Example

Configuration in this directory creates an AWS EKS cluster with necessary components for JCloud(Kong and Linkerd) with monitoring (Prometheus, OTLP Collector, Promtail and Tempo)

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Once the cluster is up and running, you can check that Karpenter is functioning as intended with the following command:

```bash
# First, make sure you have updated your local kubeconfig
aws eks --region us-east-1 update-kubeconfig --name mycluster

# Second, install JCloud operator
helm repo add jina https://jina.ai/helm-charts/
helm search repo jina
helm repo update
helm install jcloud-operator jina/jcloud-operator -n jcloud --set apimanager.enable=false --create-namespace

# Now deploy your flow/deployment
kubectl apply -f flow.yaml
```

### Tear Down & Clean-Up

Because Kong installed with ELB, you need to remove all flows and uninstall kong before you can destroy the cluster

1. Remove the flows created above

```bash
kubectl delete flow --all --all-namespaces
```

2. Remove the Resources created by Terraform

```bash
terraform destroy 
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.
