variable "aws_region" {
  description = "AWS region to deploy the cluster into."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the control plane. Pin and upgrade deliberately."
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "ID of the VPC to deploy the cluster into (from the VPC unit)."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the control plane ENIs and worker nodes (from the VPC unit)."
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Whether the cluster API endpoint is publicly accessible (CIDR-restricted)."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Tighten to office/VPN egress."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 6
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
