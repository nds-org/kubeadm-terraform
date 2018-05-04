
data "external" "k8s_join_token" {
  depends_on = ["null_resource.provision_master"]
  program = ["assets/get-token.sh"]
  query = {
    host = "${openstack_networking_floatingip_v2.masterip.address}",
    private_key  = "${var.privkey}"
  }
}


resource "null_resource" "provision_worker" {
  count = "${var.worker_count}"

  connection {
    bastion_host = "${openstack_networking_floatingip_v2.masterip.address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${module.compute_worker_nodes.worker-instance-fixed-ips[count.index]}"
    timeout      = "5m"
  }

  depends_on = ["null_resource.provision_master"]

  # Update the /etc/hosts file to prevent sudo warnings about the hostname
    provisioner "remote-exec" {
      inline = [
        "sudo hostnamectl set-hostname ${var.env_name}-worker${count.index}",
        "echo '127.0.0.1 ${var.env_name}-worker${count.index}' | sudo tee -a /etc/hosts",
        "nohup sudo reboot &"
      ]
    }

    provisioner "file" {
      source  = "assets/bootstrap.sh"
      destination = "/home/ubuntu/bootstrap.sh"
    }
    provisioner "remote-exec" {
      inline = [
        "chmod +x /home/ubuntu/bootstrap.sh",
        "/home/ubuntu/bootstrap.sh ${module.compute_worker_nodes.worker-docker-devices[count.index]}"
      ]
    }
}

resource "null_resource" "worker_join" {
  count      = "${var.worker_count}"
  depends_on = ["null_resource.provision_worker", "null_resource.provision_master"]

  connection {
    bastion_host = "${openstack_networking_floatingip_v2.masterip.address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${module.compute_worker_nodes.worker-instance-fixed-ips[count.index]}"
  }

  provisioner "remote-exec" {
    inline = [
    "sudo ${data.external.k8s_join_token.result.command}"
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "sudo kubeadm reset"
    ]
  }
}

resource "null_resource" "worker_node" {
count      = "${var.worker_count}"
depends_on = ["null_resource.provision_worker", "null_resource.provision_master"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  # Give the master a little time to process the join operation
  provisioner "local-exec" {
    command = "sleep 10"
  }

  # When we destroy a worker node remove it from the master too
  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "kubectl delete node ${var.env_name}-worker${count.index}"
    ]
  }
}


resource "null_resource" "label_external_ip_nodes" {
count      = "${var.worker_ips_count}"
depends_on = ["null_resource.worker_node"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  # Label the worker nodes that have external IP addresses
  provisioner "remote-exec" {
    inline = [
      "kubectl label node ${var.env_name}-worker${count.index} external_ip=true"
    ]
  }
}
