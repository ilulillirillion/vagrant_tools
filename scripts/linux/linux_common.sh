#!/usr/bin/env sh

#TODO: make pathing more resilient


sh ./scripts/linux/configure_root_password.sh $VAGRANT_TOOLS_ROOT_PASS
sh ./scripts/linux/configure_ssh.sh;
sh ./scripts/linux/configure_nameservers; 
