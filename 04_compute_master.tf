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
    "openstack_blockstorage_volume_v2.master_docker"
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


resource "null_resource" "provision_master" {
  depends_on = [
    "openstack_compute_floatingip_associate_v2.masterip",
    "openstack_compute_volume_attach_v2.master-docker"
  ]

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
      "/home/ubuntu/bootstrap.sh ${local.master-docker-device}"
    ]
  }

  provisioner "remote-exec" {
    script = "assets/bootstrap-master.sh"
  }

}
