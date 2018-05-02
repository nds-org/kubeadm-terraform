
resource "openstack_blockstorage_volume_v2" "master_docker" {
  name = "${var.env_name}-master-docker"
  size = "${var.docker_volume_size}"
}

resource "openstack_blockstorage_volume_v2" "worker_docker" {
  count       = "${var.worker_count}"
  name        = "${var.env_name}-worker${count.index}-docker"
  size        = "${var.docker_volume_size}"
}
