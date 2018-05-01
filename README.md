# Kubeadm Boostrapper with Terraform for OpenStack
This package enhances the [data-8 kubeadm bootstrap](https://github.com/data-8/kubeadm-bootstrap)
process by brininging in Terraform to provision the network and hosts for a
kubernetes cluster in OpenStack.

## How to Build a Cluster
Check out a copy of this repo and cd into the top directory.

### Configure variables
You will need to edit variables.tf to reflect values from your Openstack
environment as well as to establish the number of nodes you need in your
cluster.

Most of the variables should be obvious, but here is a summary with some detail
on the more specific value domains.

 | Variable | Description |
 | -------- | ----------- |
 |env_name | Root name for this cluster. Will be used to name nodes and networks |
 |pubkey | Path to a public key file which will be used to generate the key pair |
 |privkey | Path to the corresponding private key file which will be used to access the hosts |
 |pubkey_name | Name to be assigned to this key pair |
 |master_flavor | Name of the Openstack instance flavor to use for the master node |
 |master_image | Name of the OS image to be used to initialize the master node. So far, this has been tested on Ubuntu 16 |
 |worker_flavor | Name of the Openstack instance flavor to use for the worker nodes |
 |worker_image | Name of the OS image to be used to initialize the worker node. So far, this has been tested on Ubuntu 16 |
 |public_network | Name of the network that has access to the internet |
 |worker_count | How many workers to provision |

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

 ### Build the Cluster
 Now comes the easy part. To build your kubernetes cluster just issue this
 command in the root folder of this repo:
 ```bash
 % terraform apply
 ```

 ## Using the Cluster
 You now have a running cluster with the [helm tiller](https://docs.helm.sh)
 installed. To interact with it, you will need to log into your master node and
 use the `kubectl` commands from there.
