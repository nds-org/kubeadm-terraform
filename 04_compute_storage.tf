
module "compute_storage_nodes" {
  source = "./compute"
   worker_count= "${var.storage_node_count}"
   master_ip_address= "${openstack_networking_floatingip_v2.masterip.address}"
   privkey= "${var.privkey}"
   availability_zone = "${var.availability_zone}"
   env_name= "${var.env_name}"
   worker_flavor= "${var.storage_flavor}"
   worker_image= "${var.image}"
   node_type = "storage"
   key_pair_name= "${openstack_compute_keypair_v2.k8s.name}"
   security_group_name= "${openstack_compute_secgroup_v2.k8s.name}"
   docker_volume_list = "${openstack_blockstorage_volume_v2.storage_docker.*.id}"
}

resource "openstack_compute_volume_attach_v2" "storage_volume" {
  count       = "${var.storage_node_count}"
  volume_id = "${element(openstack_blockstorage_volume_v2.storage_node.*.id, count.index)}"
  instance_id = "${module.compute_storage_nodes.worker-instance-ids[count.index]}"
}

locals {
  storage-volume-devices = "${openstack_compute_volume_attach_v2.storage_volume.*.device}"
}
