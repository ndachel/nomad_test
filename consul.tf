// This is the Consul Terraform module. This module is actually bundled within
// Consul at https://github.com/hashicorp/consul in the Terraform folder.
module "consul" {
  // This is the source of the Consul module.
  source = "github.com/sethvargo/tf-consul-atlas-join"

  // This is the specific AMI id to use for the Consul servers.
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  // This tells the Consul module to create 3 servers.
  servers = 3

  // This tells the Consul module to launch inside our VPC
  subnet_id      = "${aws_subnet.hashicorp-training.id}"
  security_group = "${aws_security_group.hashicorp-training.id}"

  // These two arguments use outputs from another module. The ssh_keys module
  // we have been using outputs the key name and key path. The Consul module
  // takes those values as arguments.
  key_name         = "${aws_key_pair.hashicorp-training.key_name}"
  private_key_path = "${path.module}/${var.private_key_path}"

  // These variables are provided via our top-level module so that the Consul
  // cluster can join using Atlas. This removes the need to use a "well-known"
  // IP address to join the initial cluster, and it gives us the web interface
  // in Atlas.
  atlas_environment = "${var.atlas_environment}"
  atlas_token       = "${var.atlas_token}"
}
