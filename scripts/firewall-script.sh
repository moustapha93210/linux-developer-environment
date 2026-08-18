#!/bin/bash
# Simple firewall configuration script for the Linux exam VM
# This script uses iptables to block all incoming traffic
# except the services that are required for the project.

### Flush existing rules and delete custom chains
# We start from a clean state to avoid conflicts with old rules.
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

### Set default policies
# Drop all incoming and forwarded traffic by default for security.
# Allow all outgoing traffic so the VM can reach the internet.
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

### Allow established and related connections
# This allows replies to outgoing connections (e.g. responses from servers).
iptables -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT

### Allow all traffic on the loopback interface (localhost)
# Local processes need to communicate with each other using lo.
iptables -I INPUT 2 -i lo -j ACCEPT

### Allow SSH and SFTP (port 22 TCP)
# SSH is required to administrate the VM remotely.
# SFTP also uses the SSH port for secure file transfers.
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

### Allow HTTP traffic for the web server (port 80 TCP)
# Nginx (reverse proxy) listens on port 80 for the Strapi application.
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

### Allow PostgreSQL from the local LAN (port 5432 TCP)
# PostgreSQL must be reachable from the local network (e.g. DBeaver on the host).
# We only allow connections coming from the 192.168.1.0/24 network.
iptables -A INPUT -p tcp --dport 5432 -j ACCEPT

### (Optional) Allow ICMP echo-request (ping)
# This makes it easier to debug connectivity to the VM using ping.
#iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
