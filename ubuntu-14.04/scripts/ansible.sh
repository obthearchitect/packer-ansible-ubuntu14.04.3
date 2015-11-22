#!/bin/bash -eux

# Allow access to PPA's
sudo apt-get install -y software-properties-common

# Install the Ansible PPA
sudo apt-add-repository ppa:ansible/ansible

# Run another quick update and then install Ansible
sudo apt-get update
sudo apt-get install -y ansible