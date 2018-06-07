#!/bin/bash
sudo mkfs -t ext4 $1
sudo mkdir /rook
sudo mount -t ext4 $1 /rook

# Add the rook mount to fstab to ensure it survives reboot
lsblk -o NAME,FSTYPE,UUID,MOUNTPOINT $1 \
     |grep ext4 \
     | awk '{print "UUID="$3"  "$4"  "$2"  defaults 0 0"}' \
     >> /etc/fstab
