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

- If you are getting a 403 forbidden error, you can try docker logout public.ecr.aws as explained [here](https://docs.aws.amazon.com/AmazonECR/latest/public/public-troubleshooting.html)


- If you are interested in the daemonset for image/model pulling, get the OIDC provider ARN to be used for IAM role & service account creation later.

  ```bash
  terraform output oidc_provider_arn
  ```

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

> Skip this step if you are not worried about keeping GPU nodes alive to scale fast.

This sets up `overprovisioner` that is responsible to keep 1 or more GPU nodes alive at all times.

```bash

# Clone the `resource-manager` repo if you haven't already
# git clone https://github.com/jina-ai/resource-manager.git

cd resource-manager/deployment
kubectl apply -f namespace.yaml
kubectl apply -f .
```

##### (Optional) Install `image-puller` daemonset 

> Skip this step if you are not worried about pull time improvements.

This sets up 2 containers as a daemonset -

- `pull-images` that is responsible to pull images used by our pods - Executor, Linkerd, Knative Queue Proxy, etc. 
- `pull-models` that is responsible to pull all airgapped models from s3.


First create the IAM role with policies related to ECR & S3.

```bash
cd iam/

# change the OIDC provider ARN in `main.tf` file to the one you got from terraform output
# without this, the daemonset won't be able to pull images from ECR or models from S3
# local_cluster_oidc = "..."

terraform init
terraform plan
terraform apply --auto-approve

# Get the role ARN from terraform output
terraform output iam_role_arn
```

Create a service account in `wolf` namespace with the IAM role ARN from above.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jina-ecr-reader
  namespace: wolf
  annotations:
    eks.amazonaws.com/role-arn: <iam_role_arn>
```

Then create the daemonset in `wolf` namespace.

```bash

# Clone the `wolf` repo if you haven't already
# git clone https://github.com/jina-ai/wolf.git

cd wolf/k8s/resources/daemonset 
kubectl apply -f .
```

### Deploy the model and test

To create `base-en` model in `jnamespace-deepankar` namespace, apply the [base-model-gpu.yml](base-model-gpu.yml).

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


2. Remove `wolf` namespace (to delete `resource-manager` and `image-puller`) (if any)

```bash
kubectl delete ns wolf
```

3. Remove `jina-operator` helm chart

```bash
helm uninstall jcloud-operator -n jcloud
```

4. Remove the IAM role created by Terraform (if any)

```bash
cd iam/
terraform destroy --auto-approve
```


4. Remove the Resources created by Terraform

```bash
terraform destroy --auto-approve
```
