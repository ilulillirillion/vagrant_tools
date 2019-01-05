#!/usr/bin/env sh


# dummy password, INSECURE
echo "root:testpasswd" | chpasswd;


# Add 8.8.8.8 to /etc/resolv.conf if it's not there
grep "8.8.8.8" /etc/resolv.conf || echo "nameserver 8.8.8.8" >> /etc/resolv.conf


# Update yum repositories
#yum update -y;


# install htop
#yum install -y htop;


# Make sure password ssh is enabled (and on for root)
sed -i '/^PasswordAuthentication/s/no/yes/' /etc/ssh/sshd_config;
sed -i '/^PermitRootLogin/s/prohibit-password/yes/' /etc/ssh/sshd_config
systemctl reload sshd.service;


# TODO: remove temp files from /tmp
