resource "openstack_compute_secgroup_v2" "k8s" {
  name        = "${var.env_name}-k8s"
  description = "${var.env_name} - Kubernetes"

  rule {
    ip_protocol = "icmp"
    from_port   = "-1"
    to_port     = "-1"
    cidr        = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "tcp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
  }

  rule {
    ip_protocol = "udp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
  }

  rule {
    ip_protocol = "icmp"
    from_port   = "-1"
    to_port     = "-1"
    self        = true
  }

  rule {
    ip_protocol = "tcp"
    from_port   = "80"
    to_port     = "80"
    cidr        = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "tcp"
    from_port   = "443"
    to_port     = "443"
    cidr        = "0.0.0.0/0"
  }
}
