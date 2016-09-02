#!/bin/bash

# since we automatically remove the members, we must start from a clean state everytime
rm -rf /var/etcd/data

ETCD_CLIENT_PORT="4001" \
ETCD_SERVER_PORT="7001" \
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:7001" \
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://{{ ansible_default_ipv4.address }}:7001" \
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:4001" \
ETCD_ADVERTISE_CLIENT_URLS="http://{{ ansible_default_ipv4.address }}:4001" \
ETCD_DATA_DIR="/var/etcd/data" \
ETCD_SNAPSHOT_COUNT="1000" \
ETCD_ELECTION_TIMEOUT="2000" \
ETCD_HEARTBEAT_INTERVAL="400" \
ETCD_NAME="{{ ansible_default_ipv4.address }}" \
ALERT_URL="{{ alert_url }}" \
EC2_REGION="{{ ec2_region }}" \
DOMAIN="{{ internal_domain }}" \
python /opt/etcd/bin/etcd_proc.py
