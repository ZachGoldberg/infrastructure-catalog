terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  alarm_email   = var.alarm_email != "" ? var.alarm_email : var.email_address
  account_id    = data.aws_caller_identity.current.account_id
  region        = data.aws_region.current.name
  ses_identity  = "arn:aws:ses:${local.region}:${local.account_id}:identity/${var.email_address}"
  log_group_arn = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.function_name}"
}

# ---------------------------------------------------------------------------
# Packaging
# ---------------------------------------------------------------------------
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/${var.function_name}.zip"
}

# ---------------------------------------------------------------------------
# Execution role (least privilege)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.function_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "perms" {
  statement {
    sid       = "SendPrimeEmail"
    effect    = "Allow"
    actions   = ["ses:SendEmail"]
    resources = [local.ses_identity]
    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [var.email_address]
    }
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "ses:Recipients"
      values   = [var.email_address]
    }
  }
  statement {
    sid       = "WriteOwnLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${local.log_group_arn}:*"]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.function_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.perms.json
}

# ---------------------------------------------------------------------------
# Log group (pre-created so retention is owned here)
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ---------------------------------------------------------------------------
# Lambda
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.this.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      PRIME_INDEX   = tostring(var.prime_index)
      EMAIL_ADDRESS = var.email_address
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]
  tags       = var.tags
}

# ---------------------------------------------------------------------------
# EventBridge Scheduler (timezone-aware so 9am is local)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${var.function_name}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "scheduler_invoke" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.this.arn]
  }
}

resource "aws_iam_role_policy" "scheduler_invoke" {
  name   = "${var.function_name}-scheduler-invoke"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_invoke.json
}

resource "aws_scheduler_schedule" "this" {
  name = var.function_name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_timezone

  target {
    arn      = aws_lambda_function.this.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}

# ---------------------------------------------------------------------------
# Alarms -> SNS -> email
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  name = "${var.function_name}-alarms"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = local.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "${var.function_name}-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 86400
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  dimensions          = { FunctionName = aws_lambda_function.this.function_name }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  alarm_description   = "Lambda raised an error (includes failed SES send, which the handler re-raises)."
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "did_not_run" {
  alarm_name          = "${var.function_name}-did-not-run"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Invocations"
  namespace           = "AWS/Lambda"
  period              = 93600
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "breaching"
  dimensions          = { FunctionName = aws_lambda_function.this.function_name }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  alarm_description   = "No invocation in the last ~26h: schedule likely disabled or mistargeted."
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ses_bounce" {
  alarm_name          = "${var.function_name}-ses-delivery-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Bounce"
  namespace           = "AWS/SES"
  period              = 86400
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  alarm_description   = "SES reported a bounce: accepted-but-not-delivered email."
  tags                = var.tags
}
