locals {
  app_name = "self-heal-demo"
}

# Determine key name to use
locals {
  effective_key_name = var.key_name != "" ? var.key_name : (length(aws_key_pair.deployer) > 0 ? aws_key_pair.deployer[0].key_name : null)
}

#Default VPC 
data "aws_vpc" "default" {
default = true
}


data "aws_subnet_ids" "default" {
vpc_id = data.aws_vpc.default.id
}

# Security Group for app instances
resource "aws_security_group" "app_sg" {
  name        = "${local.app_name}-app-sg"
  description = "Allow SSH, HTTP, node_exporter"
  vpc_id      = data.aws_vpc.default.id


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "node_exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
