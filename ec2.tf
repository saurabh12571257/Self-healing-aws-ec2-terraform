# App EC2 Instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_app
  subnet_id              = data.aws_subnets.default.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = local.effective_key_name
  tags = {
    Name = "${local.app_name}-app"
  }


  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx wget
              systemctl enable nginx
              systemctl start nginx
              
              
              # install node_exporter
              useradd --no-create-home --shell /bin/false node_exporter || true
              cd /tmp
              wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
              tar xvf node_exporter-1.8.1.linux-amd64.tar.gz
              cp node_exporter-1.8.1.linux-amd64/node_exporter /usr/local/bin/
              chown node_exporter:node_exporter /usr/local/bin/node_exporter
              cat >/etc/systemd/system/node_exporter.service <<SERVICE
              [Unit]
              Description=Node Exporter
              After=network.target
              
              
              [Service]
              User=node_exporter
              ExecStart=/usr/local/bin/node_exporter
              
              
              [Install]
              WantedBy=default.target
              SERVICE
              systemctl daemon-reload
              systemctl enable node_exporter
              systemctl start node_exporter


              EOF
}
