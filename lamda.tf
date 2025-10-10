# Lambda function using S3 object
resource "aws_lambda_function" "auto_remediate" {
  function_name = "${local.app_name}-auto-remediate"
  s3_bucket     = aws_s3_bucket.lambda_bucket.id
  s3_key        = aws_s3_object.lambda_artifact.key
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30
  publish       = true
}
