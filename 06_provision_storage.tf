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
    source  = "assets/bootstrap-storage.sh"
    destination = "/home/ubuntu/bootstrap-storage.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/bootstrap-storage.sh",
      "sudo /home/ubuntu/bootstrap-storage.sh ${local.storage-volume-devices[count.index]}"
    ]
  }
}

## Label the storage node
resource "null_resource" "label_storage_nodes" {
depends_on = ["module.provision_storage_nodes"]
count      = "${var.storage_node_count}"

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  # Label the worker nodes that have external IP addresses
  provisioner "remote-exec" {
    inline = [
      "kubectl label node ${var.env_name}-storage${count.index} external-storage=true"
    ]
  }
}


resource "null_resource" "install_nfs" {
  depends_on = [
    "null_resource.provision_storage_mounts",
  ]

  # Don't install if there are no storage nodes in use
  count = "${(var.storage_node_count == 1) ? 1 : 0}"

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  provisioner "file" {
    source  = "assets/deploy-nfs.sh"
    destination = "/home/ubuntu/deploy-nfs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/deploy-nfs.sh",
      "/home/ubuntu/deploy-nfs.sh"
    ]
  }
}

resource "null_resource" "install_glfs" {
  depends_on = [
    "null_resource.provision_storage_mounts",
  ]

  # Don't install if there aren't enough storage nodes in use
  count = "${var.storage_node_count > 1 ? 1 : 0}"

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  provisioner "file" {
    source  = "assets/deploy-glfs.sh"
    destination = "/home/ubuntu/deploy-glfs.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/deploy-glfs.sh",
      "/home/ubuntu/deploy-glfs.sh ${var.storage_node_count}"
    ]
  }
}
