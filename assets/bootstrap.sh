#!/bin/bash
echo '============================'
echo '= Installing kubeadm       ='
echo '============================'
cd ~
git clone https://github.com/nds-org/kubeadm-bootstrap -b v1.1
cd kubeadm-bootstrap
sudo ./install-kubeadm.bash


echo '============================'
echo '= Updating OS Dependencies ='
echo '============================'
sudo apt-get update -qq
sudo apt-get upgrade -qq
sudo apt-get install -qq jq nfs-common
