#!/bin/bash

echo "Prepare flannel {{ flannel_version }} release ..."

mkdir /opt/flannel
mkdir /tmp/flannel
grep -q "{{ flannel_version }}" /opt/flannel/.flannel_version 2>/dev/null || {
  cd /tmp/flannel
  curl -L https://github.com/coreos/flannel/releases/download/v{{ flannel_version }}/flannel-{{ flannel_version }}-linux-amd64.tar.gz -o flannel.tgz
  tar xzf flannel.tgz
  mkdir /opt/flannel/bin
  mv flannel-{{ flannel_version }}/flanneld /opt/flannel/bin
  echo {{ flannel_version }} > /opt/flannel/.flannel_version
  rm -rf /tmp/flannel
  ln -s /opt/flannel/bin/flanneld /usr/local/bin/flanneld
}
