#!/bin/bash

echo "Prepare flannel {{ flannel_version }} release ..."

mkdir /opt/flannel
grep -q "{{ flannel_version }}" /opt/flannel/.flannel_version 2>/dev/null || {
  cd /tmp/flannel
  curl -L https://github.com/coreos/flannel/releases/download/v{{ flannel_version }}/flannel-{{ flannel_version }}-linux-amd64.tar.gz -o flannel.tgz
  tar xzf flannel.tgz
  cp flannel-{{ flannel_version }}/flanneld /usr/local/bin/flanneld

  mkdir /opt/flannel/bin
  cp *.sh /opt/flannel/bin
  cp flannel-{{ flannel_version }}/*.sh /opt/flannel/bin

  chmod 644 flannel.service
  cp flannel.service /lib/systemd/system

  cd /tmp
  #rm -rf /tmp/flannel
  echo {{ flannel_version }} > /opt/flannel/.flannel_version

  #enable the service
  rm /run/flannel/subnet.env
  /opt/flannel/bin/wait-for-etcd.sh
  systemctl start flannel
  systemctl enable flannel
}
