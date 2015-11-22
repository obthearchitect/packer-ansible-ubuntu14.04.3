#!/bin/bash -eux

# Zero out free space
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY