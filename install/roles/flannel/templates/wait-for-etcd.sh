#!/bin/bash

for i in {1..10}; do
    etcdready=`curl http://localhost:4001/health | grep true`
    if [ -n "$etcdready" ]
    then
        etcdctl set /coreos.com/network/config '{"Network":"{{ flannel_subnet }}/16", "Backend": {"Type": "VXLAN"}}'
        exit 0
    fi
    sleep 1
done
exit -1
