
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

resource "null_resource" "provision_worker" {
  count = "${var.worker_count}"

  connection {
    bastion_host = "${openstack_networking_floatingip_v2.masterip.address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${element(openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4, count.index)}"
    timeout      = "5m"
  }

  depends_on = ["null_resource.provision_master"]

  # Update the /etc/hosts file to prevent sudo warnings about the hostname
    provisioner "remote-exec" {
      inline = [
        "sudo hostnamectl set-hostname ${var.env_name}-worker${count.index}",
        "echo '127.0.0.1 ${var.env_name}-worker${count.index}' | sudo tee -a /etc/hosts",
        "sudo reboot"
      ]
    }

  provisioner "remote-exec" {
    script = "assets/bootstrap.sh"
  }
}

resource "null_resource" "worker_join" {
  count      = "${var.worker_count}"
  depends_on = ["null_resource.provision_worker", "null_resource.provision_master"]

  connection {
    bastion_host = "${openstack_networking_floatingip_v2.masterip.address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${element(openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4, count.index)}"
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

resource "null_resource" "delete_worker_node" {
count      = "${var.worker_count}"
depends_on = ["null_resource.provision_worker", "null_resource.provision_master"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }
  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "kubectl delete node ${var.env_name}-worker${count.index}"
    ]
  }
}
