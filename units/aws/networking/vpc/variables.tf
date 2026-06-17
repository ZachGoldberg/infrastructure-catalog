variable "aws_region" {
  description = "AWS region to deploy the VPC into."
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster that will use this VPC (used for subnet discovery tags)."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ). Worker nodes and pods live here."
  type        = list(string)
  default     = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ). Load balancers and NAT gateways live here."
  type        = list(string)
  default     = ["10.0.96.0/22", "10.0.100.0/22", "10.0.104.0/22"]
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT gateway (cheaper, dev). Set false for one NAT per AZ (prod HA)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
