output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group name."
  value       = aws_cloudwatch_log_group.this.name
}

output "alarm_topic_arn" {
  description = "SNS topic ARN used for alarms (empty if alarms disabled)."
  value       = local.alarm_topic
}
