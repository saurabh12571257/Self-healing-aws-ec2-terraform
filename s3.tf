resource "aws_s3_bucket_acl" "lambda_bucket" {
  bucket = "${local.app_name}-lambda-artifacts-${random_id.bucket_suffix.hex}"
  acl    = "private"
}
