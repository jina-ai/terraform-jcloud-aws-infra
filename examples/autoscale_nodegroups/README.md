# Cluster Autoscaler Example

Configuration in this directory creates an AWS EKS cluster with [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md) and one GPU ASG nodegroup using G4 instance.

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

Because Kong installed with ELB, you need to remove all flows before you can destroy the cluster

1. Remove the flows created above

```bash
kubectl delete flow --all --all-namespaces
```

2. Remove the Resources created by Terraform

```bash
terraform destroy 
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.
