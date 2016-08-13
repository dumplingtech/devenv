#!/bin/sh

export KUBE_VERSION='v1.3.5'
export KUBERNETES_PROVIDER=aws
export KUBE_AWS_ZONE=us-west-2a
export NUM_NODES=2
export MASTER_SIZE=t2.micro
export NODE_SIZE=t2.micro
#export AWS_S3_REGION=us-west-1
export AWS_S3_BUCKET=dt-k8s-artifacts
export INSTANCE_PREFIX=dt-k8s

KUBE_ROOT=$(dirname "${BASH_SOURCE}")/kubernetes

echo running ${KUBE_ROOT}/cluster/kube-up.sh
${KUBE_ROOT}/cluster/kube-up.sh

