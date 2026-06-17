locals {
  to_address    = var.ses_to_address != "" ? var.ses_to_address : var.ses_from_address
  log_group_arn = "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/${var.function_name}:*"
  identity_arn  = "arn:aws:ses:${var.aws_region}:${var.account_id}:identity/${var.ses_from_address}"
}

# Pre-create the log group so we can drop logs:CreateLogGroup from the role.
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
}

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
      values   = [var.account_id]
    }
  }
}

data "aws_iam_policy_document" "perms" {
  statement {
    sid       = "ScopedLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [local.log_group_arn]
  }
  statement {
    sid       = "ScopedSesSend"
    effect    = "Allow"
    actions   = ["ses:SendEmail"]
    resources = [local.identity_arn]
    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [var.ses_from_address]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.function_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.perms.json
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.this.arn
  runtime       = "python3.12"
  architectures = ["arm64"]
  handler       = "handler.lambda_handler"
  memory_size   = 128
  timeout       = 10
  filename      = "${path.module}/src/function.zip"

  environment {
    variables = {
      SES_FROM_ADDRESS = var.ses_from_address
      SES_TO_ADDRESS   = local.to_address
      AWS_SES_REGION   = var.aws_region
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.function_name}-schedule"
  schedule_expression = var.schedule_expression
  state               = var.schedule_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_cloudwatch_event_target" "schedule" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "events" {
  statement_id   = "AllowEventBridgeInvoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.this.function_name
  principal      = "events.amazonaws.com"
  source_arn     = aws_cloudwatch_event_rule.schedule.arn
  source_account = var.account_id
}

# --- Alarms ---
resource "aws_sns_topic" "alarms" {
  count = var.create_alarms && var.alarm_sns_topic_arn == "" ? 1 : 0
  name  = "${var.function_name}-alarms"
}

locals {
  alarm_topic = var.create_alarms ? (var.alarm_sns_topic_arn != "" ? var.alarm_sns_topic_arn : aws_sns_topic.alarms[0].arn) : ""
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.function_name}-errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = aws_lambda_function.this.function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [local.alarm_topic]
}

# Catches a disabled/missed schedule: no invocation in 25h is breaching.
resource "aws_cloudwatch_metric_alarm" "missed_invocation" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.function_name}-missed-invocation"
  namespace           = "AWS/Lambda"
  metric_name         = "Invocations"
  dimensions          = { FunctionName = aws_lambda_function.this.function_name }
  statistic           = "Sum"
  period              = 90000
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [local.alarm_topic]
}

resource "aws_cloudwatch_metric_alarm" "ses_bounce" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.function_name}-ses-bounce"
  namespace           = "AWS/SES"
  metric_name         = "Bounce"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [local.alarm_topic]
}
