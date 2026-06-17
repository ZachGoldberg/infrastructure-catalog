variable "function_name" {
  description = "Name of the Lambda function and prefix for associated resources."
  type        = string
  default     = "prime-emailer"
}

variable "recipient_email" {
  description = "Email address that receives the daily message."
  type        = string
}

variable "sender_email" {
  description = "SES-verified From address. In the SES sandbox this must be a verified identity."
  type        = string
}

variable "prime_index" {
  description = "Which prime to compute and email (1-indexed). 10 => 29."
  type        = number
  default     = 10
}

variable "schedule_expression" {
  description = "EventBridge Scheduler cron/rate expression."
  type        = string
  default     = "cron(0 9 * * ? *)"
}

variable "schedule_timezone" {
  description = "IANA timezone the schedule_expression is evaluated in (handles DST)."
  type        = string
  default     = "America/Los_Angeles"
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention for the function."
  type        = number
  default     = 14
}
