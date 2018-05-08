
module "compute_worker_nodes" {
  source = "./compute"
   worker_count= "${var.worker_count}"
   master_ip_address= "${openstack_networking_floatingip_v2.masterip.address}"
   privkey= "${var.privkey}"
   env_name= "${var.env_name}"
   worker_flavor= "${var.worker_flavor}"
   worker_image= "${var.worker_image}"
   node_type= "worker"
   key_pair_name= "${openstack_compute_keypair_v2.k8s.name}"
   security_group_name= "${openstack_compute_secgroup_v2.k8s.name}"
   docker_volume_list = "${openstack_blockstorage_volume_v2.worker_docker.*.id}"
}

resource "openstack_compute_floatingip_associate_v2" "workerip" {
  count       = "${var.worker_ips_count}"
  floating_ip = "${element(openstack_networking_floatingip_v2.workerip.*.address, count.index)}"
  instance_id = "${module.compute_worker_nodes.worker-instance-ids[count.index]}"
  fixed_ip    = "${module.compute_worker_nodes.worker-instance-fixed-ips[count.index]}"
}
