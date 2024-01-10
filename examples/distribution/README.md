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
kubectl apply -f .
```

##### (Optional) Install `image-puller` daemonset 

This sets up `image-puller` that is responsible to pull images used by our pods - Executor, Linkerd, Knative Queue Proxy, etc. 

```bash
# Clone the `wolf` repo if you haven't already
# git clone https://github.com/jina-ai/wolf.git
cd wolf/k8s/resources/daemonset # serviceaccount is specific to the cluster, be careful
kubectl apply -f .
```

##### Create `base-en` model in `jnamespace-deepankar` namespace

<details>
<summary>Expand to see the <i>base-model-gpu.yml</i> file</summary>

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: jnamespace-deepankar
---
apiVersion: jcloud.jina.ai/v1alpha1
kind: Deployment
metadata:
  labels:
    jina.ai/app: universal-embedding-api
  name: deepankar-test
  namespace: jnamespace-deepankar
spec:
  jcloud:
    autoscale:
      max: 5
      metric: concurrency
      min: 1
      revision_timeout: 300
      scale_down_delay: 30s
      stable_window: 60
      target: '180'
    expose: true
    imagepullpolicy: ifnotpresent
    labels:
      app: universal-embedding-api
      model: jina-embeddings-v2-base-en
    nodeSelector:
      karpenter.sh/capacity-type: on-demand
      karpenter.sh/provisioner-name: gpu-shared
      node.kubernetes.io/instance-type: g5.xlarge
    tolerations:
      - key: nvidia.com/gpu-shared
        operator: Exists
        effect: NoSchedule
    resources:
      capacity: on-demand
      memory: 8Gi
    docarray: 0.39.1
    version: 3.23.0
  jtype: Deployment
  with:
    name: encoder
    protocol: grpc
    uses: >-
      docker://253352124568.dkr.ecr.us-east-2.amazonaws.com/jinaai/executor-jina-embedding:v0.1.2-gpu
    uses_dynamic_batching:
      /encode:
        preferred_batch_size: 16
        timeout: 50
    uses_with:
      attn_implementation: torch
      device: cuda
      model_name_or_path: jinaai/jina-embeddings-v2-base-en
      token_batch_size: 12288
```

</details>

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
