variable "api_name" {
  description = "Name of the HTTP API."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the backing Lambda function."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the backing Lambda function (for invoke permission)."
  type        = string
}

variable "log_retention_days" {
  description = "Access log retention."
  type        = number
  default     = 30
}

variable "throttling_burst_limit" {
  description = "Burst request limit. Protects the unauthenticated endpoint from abuse/cost pre-auth."
  type        = number
  default     = 20
}

variable "throttling_rate_limit" {
  description = "Steady-state requests/sec limit."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
