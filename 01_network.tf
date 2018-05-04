data "openstack_networking_network_v2" "public_network" {
  name = "${var.public_network}"
}

resource "openstack_networking_network_v2" "network_1" {
  name           = "${var.env_name}-net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name       = "${var.env_name}-subnet"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr       = "192.168.0.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router_1" {
  name             = "${var.env_name}-router"
  external_gateway = "${data.openstack_networking_network_v2.public_network.id}"
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

resource "openstack_networking_floatingip_v2" "masterip" {
  pool = "${var.public_network}"
}

resource "openstack_networking_floatingip_v2" "workerip" {
  count = "${var.worker_ips_count}"
  pool = "${var.public_network}"
}
