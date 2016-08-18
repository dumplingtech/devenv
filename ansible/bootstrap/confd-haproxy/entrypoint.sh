#!/bin/bash

CONFIG_DIR="/etc/confd"

[ -z "$ETCD_HOST" ] && {
    echo "env var ETCD_HOST must be set"
    exit 1
}

echo "[confd-haproxy] Starting with ETCD_HOST $ETCD_HOST"

# Create etcd key paths
paths=$(grep -v '=' ${CONFIG_DIR}/conf.d/services.toml |awk -F'"' '{print $2}')
for path in $paths; do
    curl -L localhost:4001/v2/keys${path} -XPUT -d dir=true
done

# Loop until confd has updated the haproxy config
until confd -keep-stage-file=true -onetime -node $ETCD_HOST -confdir=$CONFIG_DIR; do
    echo "[confd-haproxy] waiting for intial confd run"
    file=$(ls /etc/haproxy/.haproxy.cfg* 2> /dev/null |head -n 1)
    if [ -f $file ]; then
        mv $file /etc/haproxy/haproxy.cfg
    else
	sleep 5
    fi
done

# Run confd in the background to watch the upstream servers
confd -interval 10 -node $ETCD_HOST -confdir=$CONFIG_DIR
