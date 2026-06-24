// Reference implementation. Wires Lambda + EventBridge Scheduler + SNS + DLQ +
// scoped IAM. Email recipients are passed via var.notification_emails (plain
// addresses, not secrets). No credentials are ever stored in this module.

locals {
  log_group_name = "/aws/lambda/${var.name}"
}

// Pre-create the log group so the runtime role does NOT need logs:CreateLogGroup.
resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = 30
}

resource "aws_sns_topic" "this" {
  name = var.name
}

resource "aws_sns_topic_subscription" "email" {
  for_each  = toset(var.notification_emails)
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.name}-dlq"
}

// IAM, Lambda function, schedule, topic policy, and CloudWatch alarm omitted here
// for brevity but are part of the unit: scoped sns:Publish, scoped
// lambda:InvokeFunction, and confused-deputy trust conditions per the security review.
