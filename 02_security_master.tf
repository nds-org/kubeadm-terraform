resource "openstack_compute_secgroup_v2" "k8s_master" {
  name        = "${var.env_name}-k8s-master"
  description = "${var.env_name} - Kubernetes Master"

  rule {
    ip_protocol = "tcp"
    from_port   = "6443"
    to_port     = "6443"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "bastion" {
  name        = "${var.env_name}-bastion"
  description = "${var.env_name} - Bastion Server"

  rule {
    ip_protocol = "tcp"
    from_port   = "22"
    to_port     = "22"
    cidr        = "0.0.0.0/0"
  }
}
