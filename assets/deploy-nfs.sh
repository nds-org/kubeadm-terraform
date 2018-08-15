#!/bin/bash

# Clone external-storage repo for NFS provisioner templates
git clone https://github.com/kubernetes-incubator/external-storage

# Modify StorageClass to be our default (add annotation)
echo '---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: example-nfs
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: example.com/nfs
parameters:
  mountOptions: "vers=4.1"  # TODO: reconcile with StorageClass.mountOptions
' > external-storage/nfs/deploy/kubernetes/class.yaml

# Create the storage class
kubectl create -f external-storage/nfs/deploy/kubernetes/class.yaml

# Deploy RBAC role/binding
kubectl create -f external-storage/nfs/deploy/kubernetes/rbac.yaml

# Create the NFS provisioner
kubectl create -f external-storage/nfs/deploy/kubernetes/deployment.yaml
