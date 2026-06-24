output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "schedule_arn" {
  description = "ARN of the EventBridge schedule."
  value       = aws_scheduler_schedule.daily.arn
}

output "sender_identity_arn" {
  description = "ARN of the SES verified sender identity."
  value       = aws_ses_email_identity.sender.arn
}
