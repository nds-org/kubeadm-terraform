#!/bin/bash

echo '============================='
echo '= Deploying NFS Provisioner ='
echo '============================='

# Create the NFS storage class
kubectl apply -f nfs/storageclass.yaml

# Deploy RBAC role/binding
kubectl apply -f nfs/rbac.yaml

# Create the NFS provisioner
kubectl apply -f nfs/deployment.yaml
