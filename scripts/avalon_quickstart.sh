#!/usr/bin/env bash


machines=(workstation jenkins foreman ansible polarion-node polarion-coordinator ldap);
#machines=(workstation-e01 jenkins-e01 foreman-e01 ansible-e01 polarion-node-e01 polarion-coordinator-e01);
for machine in ${machines[@]}; do vagrant destroy -f $machine; done
for machine in ${machines[@]}; do vagrant up $machine; done
