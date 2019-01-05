#!/usr/bin/env sh
# file: .../vagrant_tools/scripts/linux/configure_root_password.sh
# Sets the root password to the provided argument


# TODO: Implement alternative freebsd logic "echo 'PASS' | pw usermod root -h 0"
echo "root:$1" | chpasswd;
