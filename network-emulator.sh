#!/bin/bash

INTERFACE=enp0s3
DELAY=100ms
IP1=10.51.0.46
IP2=10.51.0.45

# Clear existing configurations
sudo tc qdisc del dev $INTERFACE root
sudo iptables -t mangle -F

# Add root qdisc
sudo tc qdisc add dev $INTERFACE root handle 1: prio

# Add child qdiscs: one for delayed traffic
sudo tc qdisc add dev $INTERFACE parent 1:3 handle 30: netem delay $DELAY

# Mark packets to IPs to exclude from delay
sudo iptables -t mangle -A OUTPUT -d $IP1 -j MARK --set-xmark 0x1/0xffffffff
sudo iptables -t mangle -A OUTPUT -d $IP2 -j MARK --set-xmark 0x1/0xffffffff

# Direct marked packets to a non-delayed band (using band 1 for simplicity)
sudo tc filter add dev $INTERFACE parent 1: protocol ip prio 1 handle 1 fw classid 1:1

# Ensure other packets go to the delayed band
sudo tc filter add dev $INTERFACE parent 1: protocol ip prio 2 u32 match ip dst 0.0.0.0/0 flowid 1:3
