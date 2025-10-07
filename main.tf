locals {
  app_name = "self-heal-demo"
}

resource "aws_key_pair" "deployer" {
  count      = var.key_name == "" ? 1 : 0
  key_name   = "${local.app_name}-key"
  public_key = file(var.public_key_path)
}
# Determine key name to use
locals {
  effective_key_name = var.key_name != "" ? var.key_name : try(aws_key_pair.deployer[0].key_name, null)
}

#Default VPC 
data "aws_vpc" "default" {
  default = true
}


data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# Find a recent Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
