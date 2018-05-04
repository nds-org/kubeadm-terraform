variable "env_name" {
  default = "bgdev"
}

variable "pubkey" {
  default = "~/.ssh/cloud.key.pub"
}

variable "privkey" {
  default = "~/.ssh/cloud.key"
}

variable "pubkey_name" {
  default = "cloud"
}

variable "master_flavor" {
  default = "m1.large"
}

variable "master_image" {
  default = "Ubuntu 16.04 LTS x86_64"
}

variable "worker_flavor" {
  default = "m1.large"
}

variable "worker_image" {
  default = "Ubuntu 16.04 LTS x86_64"
}

variable "public_network" {
  default = "ext-net"
}

variable "worker_count" {
  default = "2"
}

variable "docker_volume_size" {
  default = "75"
}
