#!/bin/bash

for i in {1..10}; do
    containerid=`docker ps | grep k8s_etcd | cut -d ' ' -f 1`
    if [ -n "$containerid" ]
    then
        docker exec -it "$containerid" etcdctl set /coreos.com/network/config '{"Network":"{{ flannel_subnet }}/16", "Backend": {"Type": "VXLAN"}}'
        exit 0
    fi
    sleep 1
done
exit -1
