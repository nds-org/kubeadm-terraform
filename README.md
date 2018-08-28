# Kubeadm Boostrapper with Terraform for OpenStack
This package enhances the [data-8 kubeadm bootstrap](https://github.com/data-8/kubeadm-bootstrap)
process by brininging in Terraform to provision the network, hosts, and storage
for a kubernetes cluster in OpenStack. It is mostly based on the brilliantly
simple article by Andre Zonca of San Diego Supercomputer Center: [Deploy scalable Jupyterhub with Kubernetes on Jetstream
](https://zonca.github.io/2017/12/scalable-jupyterhub-kubernetes-jetstream.html)

## How to Build a Cluster
Check out a copy of this repo and cd into the top directory.

### Configure variables
You will need to set some of the variables found in `variables.tf`. The best
way to do this is to create a `.tfvars` file in the `configs` directory. This
directory is in `.gitignore` to make this easy. Entries in `.tfvars` files
are just _name_ = "_value_"

Most of the variables should be obvious, but here is a summary with some detail
on the more specific value domains.

 | Variable | Description |
 | -------- | ----------- |
 |env_name | Root name for this cluster. Will be used to name nodes and networks |
 |pubkey | Path to a public key file which will be used to generate the key pair |
 |privkey | Path to the corresponding private key file which will be used to access the hosts |
 |master_flavor | Name of the Openstack instance flavor to use for the master node |
 |image | Name of the OS image to be used to initialize master nodes. So far, this has been tested on Ubuntu 16 |
 |worker_flavor | Name of the Openstack instance flavor to use for the worker nodes |
 |storage_flavor | Name of the Openstack instance flavor to use for the storage nodes |
 |external_network_id | ID of the network that has the gateway to the internet |
 |pool_name | The name of the pool from which the floating IP belongs to (usually the external network's name) |
 |availability_zone|Name of the Openstack availability zone where the hosts should be provisioned |
 |worker_count | How many workers to provision |
 | worker_ips_count | How many of the workers should be assigned an external IP address? |
 | docker_volume_size | All nodes will have external block storage attached to use as the docker storage base (/var/lib/docker). Specify the size for these volumes in GBytes |
 | storage_node_count | You can optionally provision nodes to host CEPH shared storage. This needs to be an even number. |
 | storage_node_volume_size | Specify the size of the storage attached to each storage node. Expressed in GBytes |
 | dns_nameservers | A list of IP addresses of DNS name servers available to the new subnet |


 ### Initialize Terraform
 This recipe uses Terraform to provision the network, host, and execute the
 steps to set up your cluster. You will need to [install terraform](https://www.terraform.io/intro/getting-started/install.html) on your local
 machine.

 Terraform uses a plug-in architecture. You will need to instruct it to download
 and install the plugins used in this setup.

 In the root directory of this repo execute the following command:
 ```bash
 % terraform init
 ```

 ### Set your Openstack Credentials
 Terraform makes use of the Openstack environment variables set by the script
 that you can download from your Openstack portal. Download this file and
 execute the script. It will prompt you for your password.

 ### Install `jq`
 The step that obtains the join token for the workers to connect to the
 kubernetes master requires the `jq` JSON processor. Please insure that it is
 installed on the host where you are executing the terraform command.

 ### Build the Cluster
 Now comes the easy part. To build your kubernetes cluster just issue this
 command in the root folder of this repo:
 ```bash
 % terraform apply -var-file="configs/<<your .tfvars file>>"
 ```

 ## Using the Cluster
 You now have a running cluster with the [helm tiller](https://docs.helm.sh)
 installed. To interact with it, you will need to log into your master node and
 use the `kubectl` commands from there.

 ### Extneral IP addresses
 The master node, as well as the specified number of worker nodes will have
 external IP addresses assigned. For your convenience, these nodes are all
 labeled `external_ip=true`.

### NFS Provisioner
If you configure a single storage node, it will be provisioned to run the [NFS
Provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs).
This will run a lightweight NFS server in your cluster for persistent volume claim support.

### GLFS Provisioner
If you configure 2 or more storage nodes, they will be provisioned to run the
[GlusterFS Simple Provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/gluster/glusterfs).
This will run a GlusterFS storage cluster in Kubernetes to provide distributed,
scalable persistent volume claim support.

# Resizing the cluster
Terraform makes this easy. Just adjust the values for the number of worker nodes
and reissue the
```bash
% terraform apply
```
command. Terraform will figure out what needs to change and run exactly the
required steps.

If you reduce the number of worker nodes it will remove them from the cluster
before deleting the underlying compute instance.

You can expand storage by adding new storage hosts. I don't think it will work
to try to reduce the number of storage nodes.

# Destroying the Cluster
If you want to release the resources allocated to your cluster you can destroy
the cluster with the terraform command:
```bash
% terraform destroy
```
