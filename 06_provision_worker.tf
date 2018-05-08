
module "provision_worker_nodes" {
  source = "./provision"
   worker_count= "${var.worker_count}"
   master_ip_address= "${openstack_networking_floatingip_v2.masterip.address}"
   privkey= "${var.privkey}"
   env_name= "${var.env_name}"
   node_type="worker"
   node_host_ips = "${module.compute_worker_nodes.worker-instance-fixed-ips}"
   k8s_join_command = "${lookup(data.external.k8s_join_response.result, "command")}"
   docker_device_list = "${module.compute_worker_nodes.worker-docker-devices}"
   master_provision_dependency = "${null_resource.provision_master.id}"
}
 
## Obtain a join token from the master. This will be returned as part of the
## verbatum command that can be executed on the worker to join the cluster
data "external" "k8s_join_response" {
  depends_on = ["null_resource.provision_master"]
  program = ["assets/get-token.sh"]
  query = {
    host = "${openstack_networking_floatingip_v2.masterip.address}",
    private_key  = "${var.privkey}"
  }
}


## Assign external IP addresses to the number of worker nodes as specified
## in the configuration
resource "null_resource" "label_external_ip_nodes" {
count      = "${var.worker_ips_count}"
depends_on = ["module.provision_worker_nodes"]

  connection {
    user        = "ubuntu"
    private_key = "${file("${var.privkey}")}"
    host        = "${openstack_networking_floatingip_v2.masterip.address}"
  }

  # Label the worker nodes that have external IP addresses
  provisioner "remote-exec" {
    inline = [
      "kubectl label node ${var.env_name}-worker${count.index} external_ip=true"
    ]
  }
}
