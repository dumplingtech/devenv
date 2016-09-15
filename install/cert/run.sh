#!/bin/bash

rm -rf /tmp/cert
mkdir /tmp/cert

MASTER_IP=172.20.0.9 \
MASTER_NAME=172.20.0.9 \
DNS_DOMAIN=cluster.local \
SERVICE_CLUSTER_IP_RANGE=10.3.0.0/24 \
CERT_DIR=/tmp/cert \
CERT_GROUP=staff \
./make-ca-cert.sh

