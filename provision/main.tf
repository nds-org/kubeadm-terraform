
variable "worker_count" {}
variable "master_ip_address" {}
variable "node_type" {}
variable "privkey" {}
variable "env_name" {}
variable "k8s_join_command" {}

# The list of internal IP addresses for the worker nodes
variable "node_host_ips" {
  type = "list"
}

# The list of attached volume devices to be used for docker's work dir
variable "docker_device_list" {
  type = "list"
}

variable "master_provision_dependency" {}

resource "null_resource" "provision_worker" {

  ## This introduces a hard dependency to prevent terraform from destroying
  ## the master before the workers and causing the steps that unjoin from
  ## the cluster to fail.
  triggers {
    master_provisioned = "${var.master_provision_dependency}"
  }

  lifecycle{
    create_before_destroy = true
  }

  count = "${var.worker_count}"

  connection {
    bastion_host = "${var.master_ip_address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${var.node_host_ips[count.index]}"
    timeout      = "5m"
  }

  # Update the /etc/hosts file to prevent sudo warnings about the hostname
    provisioner "remote-exec" {
      inline = [
        "sudo hostnamectl set-hostname ${var.env_name}-${var.node_type}${count.index}",
        "echo '127.0.0.1 ${var.env_name}-${var.node_type}${count.index}' | sudo tee -a /etc/hosts",
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
        "sudo /home/ubuntu/attach_docker_data_root.sh ${var.docker_device_list[count.index]}"
      ]
    }

    provisioner "file" {
      source  = "assets/bootstrap.sh"
      destination = "/home/ubuntu/bootstrap.sh"
    }
    provisioner "remote-exec" {
      inline = [
        "chmod +x /home/ubuntu/bootstrap.sh",
        "/home/ubuntu/bootstrap.sh"
      ]
    }
}

## Get the join token and command from the master and have this worker
## node join up
resource "null_resource" "worker_join" {
  count      = "${var.worker_count}"
  depends_on = ["null_resource.provision_worker"]

  connection {
    bastion_host = "${var.master_ip_address}"
    user         = "ubuntu"
    private_key  = "${file("${var.privkey}")}"
    host         = "${var.node_host_ips[count.index]}"
  }

  provisioner "remote-exec" {
    inline = [
    "sudo ${var.k8s_join_command}"
    ]
  }

  ## Perform some cleanup when we destroy the node
  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "sudo kubeadm reset"
    ]
  }
}

## This null resource just has a provisioner step that runs on the master
## to delete the node from the cluster when it is destroyed
resource "null_resource" "worker_node" {
count      = "${var.worker_count}"
depends_on = ["null_resource.worker_join"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${var.master_ip_address}"
  }

  # Give the master a little time to process the join operation
  provisioner "local-exec" {
    command = "sleep 10"
  }

  # When we destroy a worker node remove it from the master too
  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "kubectl delete node ${var.env_name}-${var.node_type}${count.index}"
    ]
  }
}
