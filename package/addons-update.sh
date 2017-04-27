#!/bin/bash
set -e -x

if [ ${DISABLE_ADDONS} == "true" ]; then
    echo "addons have been disabled"
    sleep infinity
fi

export KUBECONFIG=/etc/kubernetes/ssl/kubeconfig

while ! kubectl --namespace=kube-system get ns kube-system >/dev/null 2>&1; do
#  echo "Waiting for kubernetes API to come up..."
  sleep 2
done

cat > /tmp/rancher-service-account.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
      name: "io-rancher-system"
      namespace: "kube-system"
EOF

kubectl create -f /tmp/rancher-service-account.yaml || true 

GCR_IO_REGISTRY=${REGISTRY:-gcr.io}
DOCKER_IO_REGISTRY=${REGISTRY:-docker.io}
INFLUXDB_HOST_PATH=${INFLUXDB_HOST_PATH:-}
INFLUXDB_RETENTION=${INFLUXDB_RETENTION:-7d}

for f in $(find /etc/kubernetes/addons -name '*.yaml'); do
  sed -i "s|\$GCR_IO_REGISTRY|$GCR_IO_REGISTRY|g" ${f}
  sed -i "s|\$DOCKER_IO_REGISTRY|$DOCKER_IO_REGISTRY|g" ${f}
  sed -i "s|\$INFLUXDB_HOST_PATH|$INFLUXDB_HOST_PATH|g" ${f}
  sed -i "s|\$INFLUXDB_RETENTION|$INFLUXDB_RETENTION|g" ${f}
  kubectl --namespace=kube-system replace --force -f ${f}
done

sleep infinity
