resource "openstack_compute_instance_v2" "master" {
  name        = "${var.env_name}-master"
  flavor_name = "${var.master_flavor}"
  image_name  = "${var.image}"
  key_pair    = "${openstack_compute_keypair_v2.k8s.name}"
  availability_zone = "${var.availability_zone}"

  network {
    name = "${var.env_name}-net"
  }

  security_groups = ["${openstack_compute_secgroup_v2.k8s_master.name}",
    "${openstack_compute_secgroup_v2.bastion.name}",
    "${openstack_compute_secgroup_v2.k8s.name}",
    "default",
  ]

  depends_on = [
    "openstack_networking_router_interface_v2.router_interface_1",
    "openstack_blockstorage_volume_v2.master_docker",
    "openstack_networking_subnet_v2.subnet_1"
  ]
}

resource "openstack_compute_floatingip_associate_v2" "masterip" {
  floating_ip = "${openstack_networking_floatingip_v2.masterip.address}"
  instance_id = "${openstack_compute_instance_v2.master.id}"
  fixed_ip    = "${openstack_compute_instance_v2.master.network.0.fixed_ip_v4}"
}

resource "openstack_compute_volume_attach_v2" "master-docker" {
  volume_id = "${openstack_blockstorage_volume_v2.master_docker.id}"
  instance_id = "${openstack_compute_instance_v2.master.id}"
}

locals {
  master-docker-device = "${openstack_compute_volume_attach_v2.master-docker.device}"
}
