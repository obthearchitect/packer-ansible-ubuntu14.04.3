#!/bin/bash -eux

# Clean up
apt-get -y autoremove
apt-get -y clean

# Remove temporary files
rm -rf /tmp/*