# API Gateway v2 HTTP API for Alertmanager
resource "aws_apigatewayv2_api" "alert_webhook_api" {
  name          = "${local.app_name}-alert-webhook"
  protocol_type = "HTTP"
}


resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.alert_webhook_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auto_remediate.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.alert_webhook_api.id
  route_key = "POST /alert"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}/alert"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.alert_webhook_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_remediate.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.alert_webhook_api.execution_arn}/*/*"
}
