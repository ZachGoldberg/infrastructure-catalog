variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table the function reads/writes."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table. IAM is scoped to this ARN and its indexes only."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention. Avoids never-expire default."
  type        = number
  default     = 30
}

variable "timeout_seconds" {
  description = "Function timeout."
  type        = number
  default     = 10
}

variable "memory_mb" {
  description = "Function memory."
  type        = number
  default     = 256
}

variable "tags" {
  description = "Tags to apply to function-related resources."
  type        = map(string)
  default     = {}
}
