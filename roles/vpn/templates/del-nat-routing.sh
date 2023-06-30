#!/usr/bin/env bash
iptables -D FORWARD -i wg0 -j ACCEPT
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ip6tables -D FORWARD -i wg0 -j ACCEPT
ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
