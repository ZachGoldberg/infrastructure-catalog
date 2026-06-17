output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "schedule_name" {
  description = "Name of the EventBridge schedule."
  value       = aws_scheduler_schedule.this.name
}

output "alarm_topic_arn" {
  description = "SNS topic ARN that alarms publish to."
  value       = aws_sns_topic.alarms.arn
}
