#!/bin/bash
sudo mkfs -t ext4 $1
sudo mkdir /rook
sudo mount -t ext4 $1 /rook
