#!/bin/bash
cd ~/kubeadm-bootstrap
sudo -E ./init-master.bash

sudo apt-get install -y nfs-common
