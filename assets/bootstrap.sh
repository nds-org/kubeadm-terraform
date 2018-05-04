#!/bin/bash
cd ~
# git clone https://github.com/data-8/kubeadm-bootstrap
git clone https://github.com/nds-org/kubeadm-bootstrap.git
cd kubeadm-bootstrap
git checkout docker-vol
sudo ./install-kubeadm.bash $1
