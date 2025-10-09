resource "aws_s3_bucket_acl" "lambda_bucket" {
  bucket = "${local.app_name}-lambda-artifacts-${random_id.bucket_suffix.hex}"
  acl    = "private"
}

resource "aws_s3_object" "lambda_artifact" {
  bucket       = aws_s3_bucket_acl.lambda_bucket.id
  key          = "lambda/lambda_function.zip"
  source       = data.archive_file.lambda_zip.output_path
  etag         = filemd5(data.archive_file.lambda_zip.output_path)
  content_type = "application/zip"
}
