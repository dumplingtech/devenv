#!/bin/bash

rm -rf /tmp/cert
mkdir /tmp/cert

MASTER_IP=172.20.0.221
MASTER_NAME=172.20.0.221
DNS_DOMAIN=cluster.local
SERVICE_CLUSTER_IP_RANGE=10.3.0.0/24
CERT_DIR=/tmp/cert
CERT_GROUP=staff
CLUSTER_NAME=dumpling
CONTEXT_NAME=$CLUSTER_NAME

./make-ca-cert.sh

TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=16 count=1 2>/dev/null)
echo "${TOKEN},admin,admin" > /tmp/cert/basic_auth.csv
ADMIN_SECRET=$TOKEN

TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
echo "${TOKEN},kube_proxy,kube_proxy" >> /tmp/cert/known_tokens.csv

TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
echo "${TOKEN},kubelet,kubelet" >> /tmp/cert/known_tokens.csv
KUBETOKEN=$TOKEN

TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)
echo "${TOKEN},admin,admin" >> /tmp/cert/known_tokens.csv

kubectl config set-cluster $CLUSTER_NAME --certificate-authority=$CERT_DIR/ca.crt --embed-certs=true --server=https://$MASTER_IP --kubeconfig=/tmp/cert/kubeconfig
kubectl config set-credentials kubelet --client-certificate=$CERT_DIR/kubelet.crt --client-key=$CERT_DIR/kubelet.key --embed-certs=true --token=$KUBETOKEN --kubeconfig=/tmp/cert/kubeconfig
kubectl config set-credentials admin --username=admin --password=$ADMIN_SECRET --kubeconfig=/tmp/cert/kubeconfig
kubectl config set-context $CONTEXT_NAME --cluster=$CLUSTER_NAME --user=admin --kubeconfig=/tmp/cert/kubeconfig
kubectl config use-context $CONTEXT_NAME --kubeconfig=/tmp/cert/kubeconfig
