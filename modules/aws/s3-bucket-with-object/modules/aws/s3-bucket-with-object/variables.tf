variable "name" {
  description = "Name of the S3 bucket to create."
  type        = string
}

variable "object_key" {
  description = "Key (path) of the object to seed in the bucket."
  type        = string
  default     = "hello.txt"
}

variable "object_content" {
  description = "Content to write into the seeded object."
  type        = string
  default     = "hello world"
}
