#!/usr/bin/env sh
# file: .../vagrant_tools/scripts/linux/configure_nameservers.sh


# Add 8.8.8.8 to /etc/resolv.conf if it's not there
grep "8.8.8.8" /etc/resolv.conf || echo "nameserver 8.8.8.8" >> /etc/resolv.conf
