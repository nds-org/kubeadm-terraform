resource "openstack_compute_instance_v2" "master" {
  name        = "${var.env_name}-master"
  flavor_name = "${var.master_flavor}"
  image_name  = "${var.master_image}"
  key_pair    = "${openstack_compute_keypair_v2.k8s.name}"

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
  ]
}

resource "openstack_compute_floatingip_associate_v2" "masterip" {
  floating_ip = "${openstack_networking_floatingip_v2.masterip.address}"
  instance_id = "${openstack_compute_instance_v2.master.id}"
  fixed_ip    = "${openstack_compute_instance_v2.master.network.0.fixed_ip_v4}"
}

resource "null_resource" "provision_master" {
  depends_on = ["openstack_compute_floatingip_associate_v2.masterip"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

# Update the /etc/hosts file to prevent sudo warnings about the hostname
  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.env_name}-master",
      "echo '127.0.0.1 ${var.env_name}-master' | sudo tee -a /etc/hosts",
      "sudo reboot"
    ]
  }

  provisioner "remote-exec" {
    script = "assets/bootstrap.sh"
  }

  provisioner "remote-exec" {
    script = "assets/bootstrap-master.sh"
  }

}
