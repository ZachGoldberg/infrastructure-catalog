terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Control plane endpoint: private always on; public on but CIDR-restricted.
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs

  # IRSA / OIDC provider - foundation for least-privilege pod IAM.
  enable_irsa = true

  # Use the modern access-entry API rather than the legacy aws-auth ConfigMap.
  authentication_mode = "API"

  # Ship control plane logs to CloudWatch.
  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  # Envelope-encrypt Kubernetes secrets with a KMS key.
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-ebs-csi-driver     = {}
  }

  eks_managed_node_groups = {
    default = {
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = var.tags
}
