#!/bin/bash
mkfs -t ext4 $1
mkdir /var/lib/docker
mount $1 /var/lib/docker

# Add to fstab to make mount permenent
lsblk -o NAME,FSTYPE,UUID,MOUNTPOINT $1 \
     |grep ext4 \
     | awk '{print "UUID="$3"  "$4"  "$2"  defaults 0 0"}' \
     >> /etc/fstab
