# Embedding Models on GPU with JCloud

### Pre-requisites

##### Install required tools

1. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2. [helm](https://helm.sh/docs/intro/install/)
3. [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
4. [awscli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

---

### Setup

##### Setup EKS cluster with Terraform

Make sure to change `cluster_name` & `vpc_name` in `main.tf` to a unique name. 

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

If you are getting a 403 forbidden error, you can try docker logout public.ecr.aws as explained [here](https://docs.aws.amazon.com/AmazonECR/latest/public/public-troubleshooting.html)

##### Update your local kubeconfig

```bash
aws eks --region us-east-1 update-kubeconfig --name <cluster_name>
```

##### Install `jcloud-operator`

Enable only `deployment` operator. Disable `flow` operator & apimanager. 

```bash
helm repo add jina https://jina.ai/helm-charts/
helm search repo jina
helm repo update
helm install jcloud-operator jina/jcloud-operator -n jcloud \
    --set apimanager.enable=false \
    --set operator.customResources.deployment=true \
    --set operator.customResources.flow=false \
    --set operator.image.tag=v0.0.8 \
    --create-namespace
```

##### (Optional) Install `resource-manager` 

This sets up `overprovisioner` that is responsible to keep 1 or more GPU nodes alive at all times.

```bash
# Clone the `resource-manager` repo if you haven't already
# git clone https://github.com/jina-ai/resource-manager.git
cd resource-manager/deployment
kubectl apply -f namespace.yaml
kubectl apply -f .
```

##### (Optional) Install `image-puller` daemonset 

This sets up `image-puller` that is responsible to pull images used by our pods - Executor, Linkerd, Knative Queue Proxy, etc. 

```bash
# Clone the `wolf` repo if you haven't already
# git clone https://github.com/jina-ai/wolf.git
cd wolf/k8s/resources/daemonset 
kubectl apply -f service-account.yml # serviceaccount is specific to the cluster, be careful
kubectl apply -f .
```

##### Create `base-en` model in `jnamespace-deepankar` namespace

Apply the [base-model-gpu.yml](base-model-gpu.yml) file to create the model in the namespace. 

```bash
kubectl apply -f base-model-gpu.yml
```

Run required tests on the model.. 

---

### Clean-Up


1. Remove all Deployments created above

```bash
kubectl delete deployments.jcloud.jina.ai --all -A
```


2. (Optional) Remove `wolf` namespace (to delete `resource-manager` and `image-puller`)

```bash
kubectl delete ns wolf
```

3. Remove `jina-operator` helm chart

```bash
helm uninstall jcloud-operator -n jcloud
```


4. Remove the Resources created by Terraform

```bash
terraform destroy 
```
