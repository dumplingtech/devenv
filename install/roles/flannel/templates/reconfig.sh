#!/bin/bash

# shutdown all affected services
systemctl stop flannel
systemctl stop kubelet
systemctl stop docker

cbr0addr=`ifconfig flannel.1 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1`
/opt/docker/bin/config-cbr0.sh "$cbr0addr"

sed 's/{{ flannel_subnet }}/$cbr0addr/' /lib/systemd/system/kubelet.service > /tmp/kubelet.service
cp /tmp/kubelet.service /lib/systemd/system/kubelet.service

systemctl daemon-reload
systemctl start docker
systemctl start kubelet
systemctl start flannel


