#!/bin/bash
cd ~
git clone https://github.com/data-8/kubeadm-bootstrap
cd kubeadm-bootstrap
sudo ./install-kubeadm.bash

sudo apt-get install -y jq nfs-common
