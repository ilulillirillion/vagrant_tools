Vagrant Tools


written by: zolvaring@gmail.com


Installation:
  Should work out of the box with any Vagrant installation. May require Ansible
  to be installed.


Use:
  All machine configuration should be done in modules with ERB YAML templates.

  Core definitions (used for defaults) are found inside the core directory.

  Editing the Vagrantfile itself should only be necessary for bugfixes or
  feature additions.

  Provisioner scripts are located in the scripts directory.

  Ansible roles and data are expected at /etc/ansible.
