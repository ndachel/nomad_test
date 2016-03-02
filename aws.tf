// This stanza declares the provider we are declaring the AWS region we want
// to use. We declare this as a variable so we can access it other places in
// our Terraform configuration since many resources in AWS are region-specific.
variable "aws_region" {
  default = "us-east-1"
}

// These values come from your AWS credentials.
variable "aws_access_key" {}
variable "aws_secret_key" {}

// This stanza declares the default region for our provider. The other
// attributes such as access_key and secret_key will be read from the
// environment instead of committed to disk for security.
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

// This stanza declares a variable named "ami_map" that is a mapping of the
// Ubuntu 14.04 official hvm:ebs volumes to their region. This is used to
// demonstrate the power of multi-provider Terraform and also allows this
// tutorial to be adjusted geographically easily.
variable "aws_amis" {
  default = {
    ap-northeast-1 = "ami-d886a1b6"
    ap-southeast-1 = "ami-a17dbac2"
    eu-central-1   = "ami-99cad9f5"
    eu-west-1      = "ami-a317ced0"
    sa-east-1      = "ami-ae44ffc2"
    us-east-1      = "ami-f7136c9d"
    us-west-1      = "ami-44b1de24"
    cn-north-1     = "ami-a664f89f"
    us-gov-west-1  = "ami-30b8da13"
    ap-southeast-2 = "ami-067d2365"
    us-west-2      = "ami-46a3b427"
  }
}

// The private key.
variable "private_key_path" {
  default = "keys/hashicorp-training"
}

// The public key.
variable "public_key_path" {
  default = "keys/hashicorp-training.pub"
}

// This uploads our local keypair to AWS so we can access the instance. This
// tutorial includes a pre-packaged SSH key, so you do not need to worry about
// using your own local keys if you have them.
resource "aws_key_pair" "hashicorp-training" {
  // This is the name of the keypair. This will show up in the Amazon console
  // and API output as this "key" (since ssh-rsa AAA... is not descriptive).
  key_name = "hashicorp-training"

  // We could hard-code a public key here, as shown below:
  // public_key = "ssh-rsa AAAAB3..."
  //
  // Instead we are going to leverage Terraform's ability to read a file from
  // your local machine using the `file` attribute.
  public_key = "${file("${var.public_key_path}")}"
}

// Create a Virtual Private Network (VPC) for our tutorial. Any resources we
// launch will live inside this VPC. We will not spend much detail here, since
// these are really Amazon-specific configurations and the beauty of Terraform
// is that you only have to configure them once and forget about it!
resource "aws_vpc" "hashicorp-training" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags { Name = "hashicorp-training" }
}

// The Internet Gateway is like the public router for your VPC. It provides
// internet to-from resources inside the VPC.
resource "aws_internet_gateway" "hashicorp-training" {
  vpc_id = "${aws_vpc.hashicorp-training.id}"
  tags { Name = "hashicorp-training" }
}

// The subnet is the IP address range resources will occupy inside the VPC. Here
// we have choosen the 10.0.0.x subnet with a /24. You could choose any class C
// subnet.
resource "aws_subnet" "hashicorp-training" {
  vpc_id = "${aws_vpc.hashicorp-training.id}"
  cidr_block = "10.0.0.0/24"
  tags { Name = "hashicorp-training" }

  map_public_ip_on_launch = true
}

// The Routing Table is the mapping of where traffic should go. Here we are
// telling AWS that all traffic from the local network should be forwarded to
// the Internet Gateway created above.
resource "aws_route_table" "hashicorp-training" {
  vpc_id = "${aws_vpc.hashicorp-training.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.hashicorp-training.id}"
  }

  tags { Name = "hashicorp-training" }
}

// The Route Table Association binds our subnet and route together.
resource "aws_route_table_association" "hashicorp-training" {
  subnet_id = "${aws_subnet.hashicorp-training.id}"
  route_table_id = "${aws_route_table.hashicorp-training.id}"
}

// The AWS Security Group is akin to a firewall. It specifies the inbound
// (ingress) and outbound (egress) networking rules. This particular security
// group is intentionally insecure for the purposes of this tutorial. You should
// only open required ports in a production environment.
resource "aws_security_group" "hashicorp-training" {
  name   = "hashicorp-training-web"
  vpc_id = "${aws_vpc.hashicorp-training.id}"

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
