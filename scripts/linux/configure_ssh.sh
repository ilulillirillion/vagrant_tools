#!/usr/bin/env sh
# file: .../vagrant_tools/scripts/linux/configure_ssh.sh


# Enables password authentication when connecting via SSH
sed -i '/^PasswordAuthentication/s/no/yes/' /etc/ssh/sshd_config;


# Enables SSH as root user
sed -i '/^PermitRootLogin/s/prohibit-password/yes/' /etc/ssh/sshd_config;


# Make sure root ssh login is available
sed -i '/^PermitRootLogin/s/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config;
grep -E '^PermitRootLogin' || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config


# Reloads the SSH service to add changes to runtime config
systemctl reload sshd.service || service sshd reload;
