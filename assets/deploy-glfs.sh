#!/bin/bash
#
# Usage: ./deploy-glfs.sh <number_of_storage_nodes>
# 

# DEBUG ONLY: Set this to "echo" to neuter the script and perform a dry-run
DEBUG=""

# The host directory to store brick files
BRICK_HOSTDIR="/tmp"

# Read in the desired number of storage nodes from first arg
NODE_COUNT="$1"

# Ensure that we have enough storage nodes to run GLFS
if [ "$NODE_COUNT" -lt 2 ]; then
  echo "ERROR: Cannot deploy GlusterFS with less than 2 nodes"
  exit 1
fi

# Clone external-storage repo for NFS provisioner templates
$DEBUG git clone https://github.com/kubernetes-incubator/external-storage 

# Label storage nodes appropriately
STORAGE_NODES=$(kubectl get nodes --no-headers | grep storage | awk '{print $1}')
for node in $STORAGE_NODES; do
  $DEBUG kubectl label nodes $node storagenode=glusterfs 
done

# Create the GLFS cluster
$DEBUG kubectl apply -f external-storage/gluster/glusterfs/deploy/glusterfs-daemonset.yaml

# Wait for the GLFS cluster to come up
count="$(kubectl get pods --no-headers | grep glusterfs | grep -v provisioner | awk '{print $3}' | grep Running | wc -l)"
while [ "$count" -lt "$NODE_COUNT" ]; do
  echo "Waiting for GLFS: $count / $NODE_COUNT"
  sleep 5
  count="$(kubectl get pods --no-headers | grep glusterfs | grep -v provisioner | sed -e s/[\\n\\r]//g | awk '{print $3}' | grep -o Running | wc -l)"
done
echo "GlusterFS is now Running: $count / $NODE_COUNT"

# Retrieve GlusterFS pod IPs
PEER_IPS=$(kubectl get pods -o wide | grep glusterfs | grep -v provisioner | awk '{print $6}')

# Use pod names / IPs to exec in and perform `gluster peer probe`
for pod_ip in ${PEER_IPS}; do
  for peer_ip in ${PEER_IPS}; do
    # Skip each node probing itself
    if [ "$pod_ip" == "$peer_ip" ]; then
      continue;
    fi

    # Perform a gluster peer probe
    pod_name=$(kubectl get pods -o wide | grep $pod_ip | awk '{print $1}')
    $DEBUG kubectl exec -it $pod_name gluster peer probe $peer_ip
  done;
done;

# Dynamically build StorageClass from pod IPs (see below)
BRICK_PATHS=""
for pod_ip in ${PEER_IPS[@]}; do
  # Insert comma if we already started accumlating ips/paths
  if [ "$BRICK_PATHS" != "" ]; then
    BRICK_PATHS="$BRICK_PATHS,"
  fi

  # Build up brickrootPaths one host at a time
  BRICK_PATHS="${BRICK_PATHS}${pod_ip}:${BRICK_HOSTDIR}"
done

# Modify StorageClass to contain our GlusterFS brickrootPaths
echo "---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: glusterfs-simple
provisioner: gluster.org/glusterfs-simple
parameters:
  forceCreate: \"true\"
  volumeType: \"replica 2\"
  brickrootPaths: \"$BRICK_PATHS\"
" > external-storage/gluster/glusterfs/deploy/storageclass.yaml

# Create the storage class
$DEBUG kubectl apply -f external-storage/gluster/glusterfs/deploy/storageclass.yaml

# Bind the necessary ServiceAccount / ClusterRole
$DEBUG kubectl apply -f external-storage/gluster/glusterfs/deploy/rbac.yaml

# Create the GLFS Simple Provisioner
$DEBUG kubectl apply -f external-storage/gluster/glusterfs/deploy/deployment.yaml
