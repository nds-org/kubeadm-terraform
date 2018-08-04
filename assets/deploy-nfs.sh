#!/bin/bash

# Deploy the NFS server
kubectl create -f nfs-server.yaml
nfs_server_ip=`kubectl get svc nfs-server -o jsonpath="{.spec.clusterIP}"`

# Deploy the NFS Client provisioner
git clone https://github.com/kubernetes-incubator/external-storage


# Create the storage class
kubectl create -f external-storage/nfs-client/deploy/class.yaml


kubectl create -f external-storage/nfs-client/deploy/auth/serviceaccount.yaml -f external-storage/nfs-client/deploy/auth/clusterrole.yaml -f external-storage/nfs-client/deploy/auth/clusterrolebinding.yaml
# Create the client provisioner
cat external-storage/nfs-client/deploy/deployment.yaml | sed "s/10.10.10.60/${nfs_server_ip}/g" | sed "s?/ifs/kubernetes?/?g" | kubectl create -f -
