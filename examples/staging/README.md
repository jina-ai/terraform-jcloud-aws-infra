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

`cluster_name` must follow one of these patterns: (jcloud-stage-eks-abcde) 

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

Enable a complete deployment of the Operators and the API manager:

The Operator is lacking the instances ConfigMap, for this u need to create it 

```bash
kubectl create namespace jcloud
kubectl create configmap jcloud-instances -n jcloud --from-file=instances.yml 
```

Add the repo:

```bash
helm repo add jina https://jina.ai/helm-charts/
helm search repo jina
helm repo update
helm install jcloud-operator jina/jcloud-operator -n jcloud \
    --set apimanager.enable=true \
    --set operator.customResources.deployment=true \
    --set operator.customResources.flow=true \
    --set operator.image.tag=v0.0.8 \
    --create-namespace
```

Somehow, the Release YAML needs to be different, I would recommend using this Helm provided values:

```text
apimanager:
  affinity: {}
  autoscaling:
    enable: false
  config:
    mongo:
      url: ""
  enable: true
  existingConfigmap: jcloud-instances
  extraEnv:
    JCLOUD_INSTANCE_CONFIG: /etc/jcloud/api/instances.yml
  extraInitContainers: []
  extraLabels: {}
  image:
    pullPolicy: Always
    pullSecrets:
    - jcloud-ecr-secret
    repository: 253352124568.dkr.ecr.us-east-2.amazonaws.com/jcloud-api-manager
    sha: 64498f2f10955abaff80898e16976f67063228891b3f865600035b5f1e6f99c4
    tag: main
  ingress:
    annotations:
      kubernetes.io/ingress.class: kong
    enabled: true
    extraPaths: []
    hosts:
    - "api-stage.dev.wolf.jina.ai" (OR ANY EXPOSED ADDRESS FOR JCLOUD API)
    labels: {}
    path: /
    pathType: Prefix
    tls:
    - hosts:
      - '*.dev.wolf.jina.ai'
      secretName: dev-wolf-tls
  livenessProbe:
    failureThreshold: 3
    httpGet:
      path: /healthz
      port: 3000
    initialDelaySeconds: 15
    timeoutSeconds: 5
  nodeSelector:
    jina.ai/node-type: system
  readinessProbe:
    httpGet:
      path: /readyz
      port: 3000
    initialDelaySeconds: 15
    periodSeconds: 20
  replicas: 1
  resources:
    requests:
      cpu: 1
      memory: 2Gi
  service:
    annotations: {}
    appProtocol: ""
    enabled: true
    labels: {}
    port: 3000
    portName: api
    targetPort: 3000
    type: ClusterIP
  tolerations: []
  topologySpreadConstraints: []
clusterid: (CLUSTER NAME)
commonLabels: {}
operator:
  affinity: {}
  autoscaling:
    enable: false
  config:
    create: true
    mongo:
      url: ""
    operator:
      global:
        docarray: 0.39.1
      monitor:
        metrics: {}
        serviceMonitor: true
        traces:
          host: http://opentelemetry-collector.monitor.svc.cluster.local
          port: 4317
      network:
        domains:
        - cert:
            secret:
              name: wolf-tls
              namespace: cert-manager
          name: wolf.jina.ai
        - cert:
            secret:
              name: dev-wolf-tls
              namespace: cert-manager
          name: dev.wolf.jina.ai
        - cert:
            secret:
              name: dev-tls
              namespace: cert-manager
          name: dev.jina.ai
        healthcheck: true
      nodegroups:
        ALL:
          nodeSelector:
            jina.ai/node-type: standard
            karpenter.sh/provisioner-name: default
          resources:
            limits:
              cpu: 16
              memory: 16G
            requests:
              cpu: 0.01
              memory: 0.1G
        GPU:
          nodeSelector:
            jina.ai/node-type: gpu
            karpenter.sh/provisioner-name: gpu
          resources:
            limits:
              nvidia.com/gpu: 1
          tolerations:
          - effect: NoSchedule
            key: nvidia.com/gpu
            operator: Exists
        SHAREGPU:
          nodeSelector:
            jina.ai/node-type: gpu-shared
            karpenter.sh/provisioner-name: gpu-shared
          resources:
            limits:
              memory: 12G
              nvidia.com/gpu: 1
            requests:
              nvidia.com/gpu: 1
          tolerations:
          - effect: NoSchedule
            key: nvidia.com/gpu-shared
            operator: Exists
      storage:
        ebs:
          name: ebs-sc
        efs:
          handler: fs-0c2bffb6a378f084b
          name: efs-storageclass
  customResources:
    deployment: true
    flow: true
  debug:
    logLevel: 0
  deploymentStrategy:
    type: RollingUpdate
  extraInitContainers: []
  extraLabels: {}
  image:
    pullPolicy: Always
    pullSecrets:
    - jcloud-ecr-secret
    repository: 253352124568.dkr.ecr.us-east-2.amazonaws.com/jcloud-operator
    sha: fba58c3ceaeecca342fabc787fb63ed4e5d3483b2cbecd09c81b8c58efa1d540
    tag: latest
  livenessProbe:
    failureThreshold: 3
    httpGet:
      path: /healthz
      port: 8081
    initialDelaySeconds: 15
    timeoutSeconds: 5
  nodeSelector:
    jina.ai/node-type: system
  podLabels: {}
  rbac:
    create: true
    serviceAccount:
      create: true
  rbacProxy:
    enabled: true
    image: gcr.io/kubebuilder/kube-rbac-proxy:v0.11.0
    resources:
      limits:
        cpu: 500m
        memory: 128Mi
      requests:
        cpu: 5m
        memory: 64Mi
    securityContext:
      allowPrivilegeEscalation: false
  readinessProbe:
    httpGet:
      path: /readyz
      port: 8081
    initialDelaySeconds: 15
    periodSeconds: 20
  replicas: 1
  resources:
    requests:
      cpu: 1
      memory: 2Gi
  secretSync:
    config: {}
    enabled: false
    image:
      pullPolicy: IfNotPresent
      repository: jinaai/ecr-cred-sync
      sha: ""
      tag: d570aac-dirty__linux_amd64
  service:
    annotations: {}
    appProtocol: ""
    enabled: true
    labels: {}
    port: 8443
    portName: https
    targetPort: https
    type: ClusterIP
  serviceMonitor:
    enabled: false
    interval: 1m
    labels: {}
    path: /metrics
    relabelings: []
    scheme: http
    scrapeTimeout: 30s
    tlsConfig: {}
  tolerations: []
  topologySpreadConstraints: []
  trustCA: {}
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

### Deploy management and Universal API:

Follow the steps on each corresponding repo


### Expose metrics for Karpenter, KNative, etc...

Create all the `service-monitor` objects from the folder, and potentially expose Grafana ingress.

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
