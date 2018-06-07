
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
      "sudo /home/ubuntu/bootstrap-rook.sh ${local.storage-volume-devices[count.index]}"
    ]
  }
}

# We need to construct a custom rook-cluster.yaml which contains
# an entry for each storage node. Start with the basic template
resource "null_resource" "initialize_rook_cluster_file" {
depends_on = ["module.provision_storage_nodes"]
  provisioner "local-exec" {
    command="cp assets/rook-cluster.template.yaml rook-cluster.yaml"
  }
}

# Append an entry for each stroage node
resource "null_resource" "customize_rook_cluster_file" {
depends_on = ["null_resource.initialize_rook_cluster_file"]
count = "${var.storage_node_count}"
  provisioner "local-exec" {
    command="assets/append_rook_node.sh ${var.env_name}-storage${count.index}"
  }
}

resource "null_resource" "install_rook" {
depends_on = [
    "null_resource.provision_storage_mounts",
    "null_resource.customize_rook_cluster_file"
]

# Don't install rook chart if there are no storage nodes in use
count = "${var.storage_node_count > 0 ? 1 : 0}"

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  provisioner "file" {
    source  = "assets/deploy-rook.sh"
    destination = "/home/ubuntu/deploy-rook.sh"
  }

  provisioner "file" {
    source  = "rook-cluster.yaml"
    destination = "/home/ubuntu/rook-cluster.yaml"
  }

  provisioner "file" {
    source  = "assets/rook-storageclass.yaml"
    destination = "/home/ubuntu/rook-storageclass.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/deploy-rook.sh",
      "/home/ubuntu/deploy-rook.sh"
    ]
  }
}
