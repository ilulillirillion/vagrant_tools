#!/usr/bin/env bash


# dummy password, INSECURE
echo "root:testpasswd" | chpasswd;


# Add 8.8.8.8 to /etc/resolv.conf if it's not there
grep "8.8.8.8" /etc/resolv.conf || echo "nameserver 8.8.8.8" >> /etc/resolv.conf


# Update yum repositories
#yum update -y;


# install htop
#yum install -y htop;


# TODO: remove temp files from /tmp
