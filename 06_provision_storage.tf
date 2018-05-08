
module "provision_storage_nodes" {
  source = "./provision"
   worker_count= "${var.storage_node_count}"
   master_ip_address= "${openstack_networking_floatingip_v2.masterip.address}"
   privkey= "${var.privkey}"
   env_name= "${var.env_name}"
   node_type="storage"
   node_host_ips = "${module.compute_storage_nodes.worker-instance-fixed-ips}"
   k8s_join_command = "${lookup(data.external.k8s_join_response.result, "command")}"
   docker_device_list = "${module.compute_storage_nodes.worker-docker-devices}"
   master_provision_dependency = "${null_resource.provision_master.id}"
}

resource "null_resource" "provision_storage_mounts" {
depends_on = ["module.provision_storage_nodes"]
  count = "${var.storage_node_count}"

  connection {
    bastion_host = "${openstack_networking_floatingip_v2.masterip.address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${module.compute_storage_nodes.worker-instance-fixed-ips[count.index]}"
    timeout      = "5m"
  }

  provisioner "file" {
    source  = "assets/bootstrap-rook.sh"
    destination = "/home/ubuntu/bootstrap-rook.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/bootstrap-rook.sh",
      "/home/ubuntu/bootstrap-rook.sh ${local.storage-volume-devices[count.index]}"
    ]
  }
}

resource "null_resource" "install_rook" {
depends_on = ["null_resource.provision_storage_mounts"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  provisioner "file" {
    source  = "assets/deploy-rook.sh"
    destination = "/home/ubuntu/deploy-rook.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/deploy-rook.sh",
      "/home/ubuntu/deploy-rook.sh"
    ]
  }
}
