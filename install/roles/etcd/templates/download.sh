#!/bin/bash

# etcd
echo "Prepare etcd {{ etcd_version }} release ..."

mkdir /opt/etcd
grep -q "{{ etcd_version }}" /opt/etcd/.etcd_version 2>/dev/null || {
  mkdir /opt/etcd/bin
  cd /tmp/etcd

  # some basic things first
  apt-get update -yqq
  apt-get -yqq dist-upgrade
  apt-get install -yqq --force-yes --no-install-recommends build-essential python python-dev python-virtualenv
  wget https://bootstrap.pypa.io/get-pip.py
  python get-pip.py

  curl -L  https://github.com/coreos/etcd/releases/download/v{{ etcd_version }}/etcd-v{{ etcd_version }}-linux-amd64.tar.gz -o etcd-v{{ etcd_version }}-linux-amd64.tar.gz
  tar xzvf etcd-v{{ etcd_version }}-linux-amd64.tar.gz
  cp etcd-v{{ etcd_version }}-linux-amd64/etcd* /usr/local/bin

  echo {{ etcd_version }} > /opt/etcd/.etcd_version
  cp /tmp/etcd/etcd_* /opt/etcd/bin
  cp /tmp/etcd/run-etcd.sh /opt/etcd/bin
  /usr/local/bin/pip install -r /tmp/etcd/requirements.pip

  chmod 644 etcd.service
  cp etcd.service /lib/systemd/system
  rm -rf /var/etcd/data
  rm -rf /etc/etcd
  rm -rf /etc/systemd/system/default.etcd
  rm -rf /etc/systemd/system/etcd.service

  systemctl daemon-reload
  systemctl start etcd
  systemctl enable etcd

  rm -rf /tmp/etcd
}
