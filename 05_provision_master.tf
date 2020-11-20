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
    source  = "assets/attach_docker_data_root.sh"
    destination = "/home/ubuntu/attach_docker_data_root.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/attach_docker_data_root.sh",
      "sudo /home/ubuntu/attach_docker_data_root.sh ${local.master-docker-device}"
    ]
  }

  provisioner "file" {
    source  = "assets/bootstrap.sh"
    destination = "/home/ubuntu/bootstrap.sh"
  }
  provisioner "file" {
    source  = "assets/bootstrap-master.sh"
    destination = "/home/ubuntu/bootstrap-master.sh"
  } 
  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "chmod +x /home/ubuntu/bootstrap.sh",
      "/home/ubuntu/bootstrap.sh",
      "chmod +x /home/ubuntu/bootstrap-master.sh",
      "/home/ubuntu/bootstrap-master.sh ${var.pod_network_type}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["kubectl label node ${var.env_name}-master external_ip=true"]
  }
}
