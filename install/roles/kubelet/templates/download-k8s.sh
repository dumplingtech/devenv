#!/bin/bash

# k8s
echo "Prepare kubernetes {{ k8s_version }} release ..."

mkdir /opt/k8s
mkdir /tmp/k8s
grep -q "{{ k8s_version }}" /opt/k8s/.k8s_version 2>/dev/null || {
  cd /tmp/k8s
  curl -L https://github.com/kubernetes/kubernetes/releases/download/v{{ k8s_version }}/kubernetes.tar.gz -o kubernetes.tar.gz
  tar xzf kubernetes.tar.gz
  pushd kubernetes/server
  tar xzf kubernetes-server-linux-amd64.tar.gz
  popd
  mv kubernetes/server/kubernetes/server/bin /opt/k8s/bin
  echo {{ k8s_version }} > /opt/k8s/.k8s_version
  rm -rf /tmp/k8s

  ln -s /opt/k8s/bin/kubectl /usr/local/bin/
}
