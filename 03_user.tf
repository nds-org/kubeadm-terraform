resource "openstack_compute_keypair_v2" "k8s" {
  name       = "${var.env_name}-key_pair"
  public_key = "${file(var.pubkey)}"
}
