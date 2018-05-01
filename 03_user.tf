resource "openstack_compute_keypair_v2" "k8s" {
  name       = "${var.pubkey_name}"
  public_key = "${file(var.pubkey)}"
}
