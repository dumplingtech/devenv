#!/bin/bash

flanneladdr=`ifconfig flannel.1 | grep "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1`
flannelmtu=`ifconfig flannel.1 | grep MTU | cut -d ":" -f 2 | cut -d " " -f 1`

echo "configuring cbr0 to use ${flanneladdr} mtu ${flannelmtu}"
# remove the existing docker0 and cbr0 setup
iptables -t nat -F
ip link set docker0 down
ip link delete docker0
ip link set cbr0 down
ip link delete cbr0

rm -rf /var/lib/docker/network

# add cbr0
brctl addbr cbr0
ifconfig cbr0 ${flanneladdr} up
ifconfig cbr0 netmask 255.255.255.0 broadcast 0.0.0.0
ip link set dev cbr0 up
iptables -t nat -A POSTROUTING ! -d "$flanneladdr" -m addrtype ! --dst-type LOCAL -j MASQUERADE

if [ -z "$flannelmtu" ]
then
    flannelmtu=1450
fi
echo {\"mtu\": ${flannelmtu}} > /opt/docker/config.json
