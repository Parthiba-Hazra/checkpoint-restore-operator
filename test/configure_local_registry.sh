#!/bin/bash

# Set variables
kind_cluster_name="${KIND_CLUSTER_NAME}"
reg_port="${REGISTRY_PORT}"
registry_name="${REGISTRY_NAME}"
registry_dir="/etc/containerd/certs.d/localhost:${reg_port}"
config_map_name="local-registry-hosting"
namespace="kube-public"

# Configure Local Registry in Kind Nodes
for node in $(kind get nodes --name "${kind_cluster_name}"); do
  docker exec "${node}" mkdir -p "${registry_dir}"
  cat <<EOF | docker exec -i "${node}" tee "${registry_dir}/hosts.toml"
[host."http://${registry_name}:${reg_port}"]
EOF
done

if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${registry_name}")" = 'null' ]; then
  docker network connect "kind" "${registry_name}"
fi

# Document Local Registry in Kubernetes
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${config_map_name}
  namespace: ${namespace}
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
