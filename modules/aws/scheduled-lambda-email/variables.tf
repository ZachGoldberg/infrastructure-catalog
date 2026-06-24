variable "function_name" {
  description = "Name of the Lambda function (also used for the log group and schedule)."
  type        = string
  default     = "prime-email-daily"
}

variable "prime_index" {
  description = "Which prime to compute and email (1-based; 10 => the 10th prime, 29)."
  type        = number
  default     = 10
}

variable "email_address" {
  description = "Verified SES identity used as both sender and recipient."
  type        = string
}

variable "schedule_expression" {
  description = "EventBridge Scheduler cron expression (evaluated in schedule_timezone)."
  type        = string
  default     = "cron(0 9 * * ? *)"
}

variable "schedule_timezone" {
  description = "IANA timezone the schedule is evaluated in, so 9am means local time."
  type        = string
  default     = "America/New_York"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the function."
  type        = number
  default     = 14
}

variable "alarm_email" {
  description = "Email subscribed to the SNS alarm topic. Defaults to email_address."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
