#!/bin/bash

# Create the NFS storage class
kubectl create -f nfs/storageclass.yaml

# Deploy RBAC role/binding
kubectl create -f nfs/rbac.yaml

# Create the NFS provisioner
kubectl create -f nfs/deployment.yaml
