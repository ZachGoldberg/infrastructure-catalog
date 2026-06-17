variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "account_id" {
  description = "AWS account ID, used for confused-deputy conditions."
  type        = string
}

variable "ses_from_address" {
  description = "Verified SES identity to send from (and to). Config, not a secret."
  type        = string
}

variable "ses_to_address" {
  description = "Recipient address. Defaults to ses_from_address when empty."
  type        = string
  default     = ""
}

variable "schedule_expression" {
  description = "EventBridge schedule expression."
  type        = string
  default     = "rate(1 day)"
}

variable "schedule_enabled" {
  description = "Whether the EventBridge schedule is enabled."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}

variable "create_alarms" {
  description = "Create CloudWatch alarms: Lambda Errors, missed-invocation, SES bounce."
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications. If empty and create_alarms is true, a topic is created."
  type        = string
  default     = ""
}
