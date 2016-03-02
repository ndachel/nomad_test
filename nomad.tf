# The number of nomad servers to create.
variable "nomad_servers" { default = 3 }

# Setup our Nomad servers.
resource "aws_instance" "nomad_server" {
  count = "${var.nomad_servers}"
  ami   = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.hashicorp-training.key_name}"
  subnet_id     = "${aws_subnet.hashicorp-training.id}"

  vpc_security_group_ids = ["${aws_security_group.hashicorp-training.id}"]

  tags { Name = "nomad-server-${count.index}" }

  connection {
    user     = "ubuntu"
    key_file = "${path.module}/${var.private_key_path}"
  }

  provisioner "remote-exec" {
    scripts = [
      # Wait for cloud-init...
      "${path.module}/scripts/wait-for-ready.sh",

      # Install the Consul agent - the Nomad server will communicate with this
      # agent for service discovery.
      "${path.module}/scripts/consul-client/install.sh",

      # Install the Nomad binary and configure it to run as a server.
      "${path.module}/scripts/nomad-server/install.sh",
    ]
  }

  # Write our Nomad server configuration file.
  provisioner "remote-exec" {
    inline = <<CMD
sudo tee /etc/nomad.d/nomad.hcl > /dev/null <<"EOF"
data_dir   = "/opt/nomad/data"
datacenter = "${var.aws_region}"

server {
  enabled = true
  bootstrap_expect = "${var.nomad_servers}"
}

atlas {
  infrastructure = "${var.atlas_environment}"
  token          = "${var.atlas_token}"
}

addresses {
  # This is actually very insecure, since it allows anyone to submit jobs to
  # your cluster. Normally you want to bind to 127.0.0.1 to only allow local
  # connections or bind to the private_ip to only allow connections which are
  # inside your data center.
  http = "0.0.0.0"
  rpc  = "${self.private_ip}"
  serf = "${self.private_ip}"
}
EOF

sudo service nomad restart
timeout 30 /bin/bash -c \
  "while true; do nomad server-join ${aws_instance.nomad_server.0.private_ip} && break; sleep 1; done"
CMD
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'ATLAS_TOKEN=${var.atlas_token}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'NODE_NAME=nomad-server-${count.index}' | sudo tee -a /etc/service/consul &>/dev/null",
      "sudo service consul restart",
    ]
  }
}

# Setup our Nomad clients.
resource "aws_instance" "nomad_client" {
  count = 1
  ami   = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.small"
  key_name      = "${aws_key_pair.hashicorp-training.key_name}"
  subnet_id     = "${aws_subnet.hashicorp-training.id}"

  vpc_security_group_ids = ["${aws_security_group.hashicorp-training.id}"]

  tags { Name = "nomad-client-${count.index}" }

  connection {
    user     = "ubuntu"
    key_file = "${path.module}/${var.private_key_path}"
  }

  provisioner "remote-exec" {
    scripts = [
      # Wait for cloud-init...
      "${path.module}/scripts/wait-for-ready.sh",

      # Install Docker - this the driver for Nomad jobs.
      "${path.module}/scripts/docker/install.sh",

      # Install the Consul agent.
      "${path.module}/scripts/consul-client/install.sh",

      # Install the Nomad binary and configure it to run as a server.
      "${path.module}/scripts/nomad-client/install.sh",
    ]
  }

  # Write our Nomad client configuration file.
  provisioner "remote-exec" {
    inline = <<CMD
sudo tee /etc/nomad.d/nomad.hcl > /dev/null <<"EOF"
data_dir   = "/opt/nomad/data"
datacenter = "${var.aws_region}"

client {
  enabled = true
  servers = [${join(",", formatlist("\"%s:4647\"", aws_instance.nomad_server.*.private_ip))}]

  meta {
    host_ip = "${self.private_ip}"
  }
}
EOF

sudo service nomad restart
CMD
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'ATLAS_TOKEN=${var.atlas_token}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'NODE_NAME=nomad-client-${count.index}' | sudo tee -a /etc/service/consul &>/dev/null",
      "sudo service consul restart",
    ]
  }
}

output "nomad-server" { value = "http://${aws_instance.nomad_server.0.public_ip}:4646" }

output "nomad-client" { value = "${aws_instance.nomad_client.0.public_ip}" }
