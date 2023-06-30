#!/usr/bin/env bash
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
ip6tables -A FORWARD -i wg0 -j ACCEPT
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE


