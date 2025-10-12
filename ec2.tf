# App EC2 Instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_app
  subnet_id              = data.aws_subnets.default.ids[0]
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

# Monitoring EC2 Instance (Prometheus + Alertmanager)
resource "aws_instance" "monitor" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_monitor
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.monitor_sg.id]
  key_name               = local.effective_key_name
  tags = {
    Name = "${local.app_name}-monitor"
  }

  user_data = <<-EOF
            #!/bin/bash
            apt-get update -y
            apt-get install -y wget tar


            # prometheus
            cd /opt
            wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
            tar xvf prometheus-2.45.0.linux-amd64.tar.gz
            mv prometheus-2.45.0.linux-amd64 prometheus
            useradd --no-create-home --shell /bin/false prometheus || true
            mkdir -p /etc/prometheus /var/lib/prometheus
            chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /opt/prometheus

            cat >/etc/prometheus/prometheus.yml <<PROM
            global:
                scrape_interval: 10s


            rule_files:
                - "/etc/prometheus/alert.rules.yml"


            alerting:
                alertmanagers:
                    - static_configs:
                        - targets: ['localhost:9093']


            scrape_configs:
                - job_name: 'node_exporter_metrics'
                  static_configs:
                    - targets: ['${aws_instance.app.private_ip}:9100']
            PROM

            cat >/etc/prometheus/alert.rules.yml <<RULES
            groups:
            - name: ec2-alerts
              rules:
              - alert: HighCPUUsage
                expr: avg(rate(node_cpu_seconds_total{mode="user"}[2m])) by (instance) > 0.85
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: "High CPU usage detected on {{ $labels.instance }}"
                  description: "Instance CPU usage > 85% for 2 minutes"
              - alert: InstanceDown
                expr: up == 0
                for: 1m
                labels:
                    severity: critical
                annotations:
                    description: "Instance {{ $labels.instance }} seems down."
                    summary: "InstanceDown alert for {{ $labels.instance }}"
            RULES


            # Install and start prometheus
            cat >/etc/systemd/system/prometheus.service <<SERVICE
            [Unit]
            Description=Prometheus
            After=network.target


            [Service]
            User=prometheus
            ExecStart=/opt/prometheus/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus
            Restart=always


            [Install]
            WantedBy=multi-user.target
            SERVICE


            systemctl daemon-reload
            systemctl enable prometheus
            systemctl start prometheus


            # alertmanager
            cd /opt
            wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
            tar xvf alertmanager-0.27.0.linux-amd64.tar.gz
            mv alertmanager-0.27.0.linux-amd64 alertmanager
            mkdir -p /etc/alertmanager


            cat >/etc/alertmanager/alertmanager.yml <<AM
            global:
                resolve_timeout: 5m


            route:
                receiver: 'lambda-webhook'


            receivers:
            - name: 'lambda-webhook'
              webhook_configs:
              - url: '${aws_apigatewayv2_api.alert_webhook_api.api_endpoint}'
                send_resolved: true
            AM


            cat >/etc/systemd/system/alertmanager.service <<SERVICE
            [Unit]
            Description=Alertmanager
            After=network.target


            [Service]
            ExecStart=/opt/alertmanager/alertmanager --config.file=/etc/alertmanager/alertmanager.yml
            Restart=always


            [Install]
            WantedBy=multi-user.target
            SERVICE


            systemctl daemon-reload
            systemctl enable alertmanager
            systemctl start alertmanager


            EOF

  depends_on = [aws_instance.app, aws_apigatewayv2_api.alert_webhook_api]
}
