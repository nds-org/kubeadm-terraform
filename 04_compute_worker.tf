
data "external" "k8s_join_token" {
  depends_on = ["null_resource.provision_master"]
  program = ["assets/get-token.sh"]
  query = {
    host = "${openstack_networking_floatingip_v2.masterip.address}",
    private_key  = "${var.privkey}"
  }
}


resource "openstack_compute_instance_v2" "worker" {
  count       = "${var.worker_count}"
  name        = "${var.env_name}-worker${count.index}"
  flavor_name = "${var.worker_flavor}"
  image_name  = "${var.worker_image}"
  key_pair    = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.env_name}-net"
  }

  security_groups = [
    "${openstack_compute_secgroup_v2.k8s.name}",
    "default",
  ]
}

resource "openstack_compute_volume_attach_v2" "worker-docker" {
  count       = "${var.worker_count}"
  volume_id   = "${element(openstack_blockstorage_volume_v2.worker_docker.*.id, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.worker.*.id, count.index)}"
}

locals {
  worker-docker-devices = "${openstack_compute_volume_attach_v2.worker-docker.*.device}"
}


resource "openstack_compute_floatingip_associate_v2" "workerip" {
  count       = "${var.worker_ips_count}"

  floating_ip = "${element(openstack_networking_floatingip_v2.workerip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.worker.*.id, count.index)}"
  fixed_ip    = "${element(openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4, count.index)}"
}
