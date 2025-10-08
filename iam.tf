# IAM role for Lambda with EC2 permissions
resource "aws_iam_role" "lambda_role" {
  name = "${local.app_name}-lambda-role"


  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "${local.app_name}-lambda-ec2-policy"
  role = aws_iam_role.lambda_role.id


  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:RebootInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}
