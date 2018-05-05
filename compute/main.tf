
variable "worker_count" {}
variable "master_ip_address" {}
variable "privkey" {}
variable "env_name" {}
variable "worker_flavor" {}
variable "worker_image" {}
variable "key_pair_name" {}
variable "security_group_name" {}
variable "docker_volume_list" {
  type = "list"
}

resource "openstack_compute_instance_v2" "worker" {
  count       = "${var.worker_count}"
  name        = "${var.env_name}-worker${count.index}"
  flavor_name = "${var.worker_flavor}"
  image_name  = "${var.worker_image}"
  key_pair    = "${var.key_pair_name}"

  network {
    name = "${var.env_name}-net"
  }

  security_groups = [
    "${var.security_group_name}",
    "default"
  ]
}

resource "openstack_compute_volume_attach_v2" "worker-docker" {
  count       = "${var.worker_count}"
  volume_id   = "${var.docker_volume_list[count.index]}"
  instance_id = "${element(openstack_compute_instance_v2.worker.*.id, count.index)}"
}

output worker-docker-devices {
  value = "${openstack_compute_volume_attach_v2.worker-docker.*.device}"
}

output worker-instance-ids {
  value = "${openstack_compute_instance_v2.worker.*.id}"
}

output worker-instance-fixed-ips {
  value = "${openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4}"
}
