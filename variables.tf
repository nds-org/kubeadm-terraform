variable "env_name" {
  default = "bgdev"
}

variable "pubkey" {
  default = "~/.ssh/cloud.key.pub"
}

variable "privkey" {
  default = "~/.ssh/cloud.key"
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

variable "public_network" {
  default = "ext-net"
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
