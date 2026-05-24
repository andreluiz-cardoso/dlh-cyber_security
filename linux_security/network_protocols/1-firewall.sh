#!/bin/bash
iptables -P INPUT DROP
iptables -A INPUT -i lo -j ACCEPT; iptables -A INPUT -n state --state ESTABLISHED,RELATED -j ACCEPT; iptables
-A INPUT -p tcp --dport 22 -j ACCEPT
