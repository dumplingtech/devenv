#!/bin/bash

netaddr="$1"
if [ -z "$1" ]
then
    # If there is no subnet provided, we configure cbr0 on 10.2.0.0 network if it doesn't exist
    cbr0=`ifconfig -a | grep cbr0`
    if [ -n "$cbr0" ]
    then
        exit 0
    fi

    netaddr="{{ flannel_subnet }}"
fi

# remove the existing docker0 and cbr0 setup
iptables -t nat -F
ip link set docker0 down
ip link delete docker0
ip link set cbr0 down
ip link delete cbr0

rm -rf /var/lib/docker/network

# add cbr0
brctl addbr cbr0
ifconfig cbr0 "$netaddr" up
ifconfig cbr0 netmask 255.255.255.0 broadcast 0.0.0.0
ip link set dev cbr0 up
iptables -t nat -A POSTROUTING ! -d "$netaddr" -m addrtype ! --dst-type LOCAL -j MASQUERADE
