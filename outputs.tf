output "app_public_ip" {
  value = aws_instance.app.public_ip
}

output "monitor_public_ip" {
  value = aws_instance.monitor.public_ip
}

output "prometheus_ui" {
  value = "http://${aws_instance.monitor.public_ip}:9090"
}

output "alertmanager_ui" {
  value = "http://${aws_instance.monitor.public_ip}:9093"
}

output "alert_webhook_endpoint" {
  value = aws_apigatewayv2_api.alert_webhook_api.api_endpoint
}
