variable "env_name" {
  default = "kubeadm"
}

variable "pubkey" {
  default = "~/.ssh/id_rsa.pub"
}

variable "privkey" {
  default = "~/.ssh/id_rsa"
}

variable "master_flavor" {
  default = "m1.large"
}

variable "image" {
  default = "Ubuntu 16.04 LTS x86_64"
}

variable "worker_flavor" {
  default = "m1.large"
}

variable "storage_flavor" {
  default = "m1.large"
}

variable "public_network" {
  default = "ext-net"
}

variable "availability_zone" {
  default = ""
}

variable "worker_count" {
  default = "1"
}

variable "worker_ips_count" {
  default = "1"
}

variable "docker_volume_size" {
  default = "75"
}

variable "storage_node_count" {
  default = "2"
}

variable "storage_node_volume_size" {
  default = "50"
}

variable "dns_nameservers" {
  description = "An array of DNS name server names used by hosts in this subnet."
  type        = "list"
  default     = []
}
