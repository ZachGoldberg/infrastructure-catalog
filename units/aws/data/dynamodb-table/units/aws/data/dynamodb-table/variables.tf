variable "table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery (continuous backups). Should stay on for stateful game-save data."
  type        = bool
  default     = true
}

variable "deletion_protection_enabled" {
  description = "Prevent accidental table deletion."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the table."
  type        = map(string)
  default     = {}
}
