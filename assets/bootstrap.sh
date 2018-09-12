#!/bin/bash
cd ~
git clone https://github.com/nds-org/kubeadm-bootstrap
cd kubeadm-bootstrap
sudo ./install-kubeadm.bash

sudo apt-get install -y jq nfs-common
