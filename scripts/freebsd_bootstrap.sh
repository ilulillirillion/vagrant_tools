#!/usr/bin/env sh


# dummy password, INSECURE
#echo "root:testpasswd" | chpasswd;
echo 'testpasswd' | pw usermod root -h 0


# Add 8.8.8.8 to /etc/resolv.conf if it's not there
grep "8.8.8.8" /etc/resolv.conf || echo "nameserver 8.8.8.8" >> /etc/resolv.conf


# install bash
pkg install -y bash


# TODO: remove temp files from /tmp
