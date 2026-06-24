variable "name" {
  description = "Name prefix for all resources (function, topic, schedule, roles)."
  type        = string
}

variable "handler_source_dir" {
  description = "Path to the directory containing the Lambda handler source to package."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Lambda handler entrypoint."
  type        = string
  default     = "main.handler"
}

variable "memory_mb" {
  description = "Lambda memory in MB."
  type        = number
  default     = 128
}

variable "timeout_seconds" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10
}

variable "schedule_expression" {
  description = "EventBridge Scheduler cron/rate expression, e.g. cron(0 9 * * ? *)."
  type        = string
}

variable "schedule_expression_timezone" {
  description = "IANA timezone for the schedule, e.g. America/Los_Angeles. Required to avoid DST drift."
  type        = string
}

variable "notification_emails" {
  description = "Email addresses to subscribe to the SNS topic. Each requires a one-time confirmation click."
  type        = list(string)
}

variable "error_alarm_actions" {
  description = "Optional SNS topic ARNs to notify when the Lambda Errors alarm fires."
  type        = list(string)
  default     = []
}
