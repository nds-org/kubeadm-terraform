#!/bin/bash
sudo mkfs -t ext4 $1
sudo mkdir /vol_b
sudo mount -t ext4 $1 /vol_b
