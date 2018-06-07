#!/bin/bash
git clone https://github.com/groundnuty/k8s-wait-for.git

sudo helm repo add rook-alpha https://charts.rook.io/alpha
sudo helm install rook-alpha/rook --name rook --version 0.6.2 --namespace rook

# Wait for the rook operator to launch
k8s-wait-for/wait_for.sh pod -l "app=rook-operator" -n rook

# Now make sure the agent deamonset is running
until [ $(kubectl get ds -n rook | grep "rook-agent" | wc | awk '{print($1)}') != 0 ]
do
  echo "No rook agents running"
  sleep 5s
done

until [ $(kubectl get ds -n rook | grep "rook-agent" | awk '{print ($2==$4)'}) = 1 ]
do
  echo "Rook Agents Not ready"
  sleep 5s
done

# Now we can install the cluster
sudo kubectl create -f rook-cluster.yaml

# And create a storage class
sudo kubectl create -f rook-storageclass.yaml
