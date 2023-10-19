MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Transfer-Encoding: 7bit
Content-Type: text/x-shellscript
Mime-Version: 1.0

#!/bin/bash
set -ex
cat <<-EOF > /etc/profile.d/bootstrap.sh
export CONTAINER_RUNTIME="containerd"
EOF
# echo "$(jq ".systemReserved.cpu=300m | .systemReserved.memory=0.5Gi | .systemReserved.ephemeral-storage=1Gi" /etc/kubernetes/kubelet/kubelet-config.json)" > /etc/kubernetes/kubelet/kubelet-config.json
# echo "$(jq ".maxPods=110" /etc/kubernetes/kubelet/kubelet-config.json)" > /etc/kubernetes/kubelet/kubelet-config.json
# echo "$(jq ".imageGCHighThresholdPercent=80 | .imageGCLowThresholdPercent=60" /etc/kubernetes/kubelet/kubelet-config.json)" > /etc/kubernetes/kubelet/kubelet-config.json
# Source extra environment variables in bootstrap script
sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh

--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
set -ex
B64_CLUSTER_CA=${certificate_authority}
API_SERVER_URL=${api_server_endpoint}
K8S_CLUSTER_DNS_IP=172.20.0.10
/etc/eks/bootstrap.sh ${cluster_name} \
  --dns-cluster-ip $K8S_CLUSTER_DNS_IP \
  --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL \
  --use-max-pods false --cni-prefix-delegation-enabled \
  --kubelet-extra-args '--max-pods=110 --system-reserved cpu=300m,memory=0.5Gi,ephemeral-storage=1Gi --eviction-hard memory.available<200Mi,nodefs.available<10% --image-gc-high-threshold=80 --image-gc-low-threshold=60' \
  --container-runtime containerd

--//--