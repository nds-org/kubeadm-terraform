#!/bin/bash
mkfs -t ext4 $1
mkdir /data
mount -t ext4 $1 /data

# It can take a few seconds for the new partition to
# be mounted and the filesystem type to be available
until [ $(lsblk -o NAME,FSTYPE,UUID,MOUNTPOINT $1 | grep "ext4" | wc | awk '{print($1)}') != 0 ]
do
  echo "Rook partition not yet available"
  sleep 5s
done

# Add the mount to fstab to ensure it survives reboot
lsblk -o NAME,FSTYPE,UUID,MOUNTPOINT $1 \
     |grep ext4 \
     | awk '{print "UUID="$3"  "$4"  "$2"  defaults 0 0"}' \
     >> /etc/fstab

# Make directory to store Persistent Volume Claims for NFS client provisioner
mkdir /data/pvc
