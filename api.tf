# API Gateway v2 HTTP API for Alertmanager
resource "aws_apigatewayv2_api" "alert_webhook_api" {
  name          = "${local.app_name}-alert-webhook"
  protocol_type = "HTTP"
}

