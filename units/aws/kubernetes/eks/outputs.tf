output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA cert for the cluster."
  value       = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA."
  value       = module.eks.oidc_provider_arn
}
