#!/bin/sh

#
# This assumes that awscli is installed already. If not, do sudo pip install awscli (on osx: sudo pip install --ignore-installed awscli)
#

# Get the binary
release='v1.3.5'
curl -L -O https://github.com/kubernetes/kubernetes/releases/download/${release}/kubernetes.tar.gz
tar xvzf kubernetes.tar.gz

# v1.3.5 currently has some bugs
# cp kubernetes/cluster/aws/config-default.sh kubernetes/cluster/aws/config-default.sh.orig
# cp kubernetes/cluster/common.sh kubernetes/cluster/common.sh.orig
# cp ./patch/config-default.sh kubernetes/cluster/aws/config-default.sh
# cp ./patch/common.sh kubernetes/cluster

