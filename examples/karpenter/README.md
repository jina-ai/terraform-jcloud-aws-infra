# Karpenter Example

Configuration in this directory creates an AWS EKS cluster with [Karpenter](https://karpenter.sh/) and one shared GPU nodegroup using G4 instance, one GPU nodegroup using G4 instance.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

If you are getting a 403 forbidden error, you can try docker logout public.ecr.aws as explained [here](https://docs.aws.amazon.com/AmazonECR/latest/public/public-troubleshooting.html)

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

Because Karpenter manages the state of node resources outside of Terraform, Karpenter created resources will need to be de-provisioned first before removing the remaining resources with Terraform.

1. Remove the example deployment created above and any nodes created by Karpenter

```bash
helm uninstall karpenter -n karpenter
kubectl delete node -l karpenter.sh/provisioner-name=default
kubectl delete node -l karpenter.sh/provisioner-name=gpu
kubectl delete node -l karpenter.sh/provisioner-name=shared
```


Because Kong installed with ELB, you need to remove all flows and uninstall kong before you can destroy the cluster

2. Remove the flows created above

```bash
kubectl delete flow --all --all-namespaces
```

3. Remove the Resources created by Terraform

```bash
terraform destroy 
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.
