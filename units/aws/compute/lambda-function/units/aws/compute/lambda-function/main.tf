terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/${var.function_name}.zip"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_iam_role" "this" {
  name = "${var.function_name}-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "dynamodb" {
  name = "${var.function_name}-dynamodb"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GameDataTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      },
      {
        Sid    = "ScopedLogging"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.this.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "xray" {
  name = "${var.function_name}-xray"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.this.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = var.timeout_seconds
  memory_size      = var.memory_mb
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.this]
  tags       = var.tags
}
