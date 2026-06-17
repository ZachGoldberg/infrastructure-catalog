# EKS Cluster

Opinionated EKS cluster wrapping terraform-aws-modules/eks.

Defaults baked in:
- Managed node groups across the VPC's private subnets (3 AZs).
- IRSA / OIDC provider enabled for least-privilege pod IAM.
- Access-entry authentication mode (not the legacy aws-auth ConfigMap).
- Control plane logging (api/audit/authenticator) to CloudWatch.
- KMS envelope encryption for Kubernetes secrets.
- Core managed addons: coredns, kube-proxy, vpc-cni, aws-ebs-csi-driver.
- Private API endpoint always on; public endpoint on but CIDR-restricted (tighten `public_access_cidrs`).

`vpc_id` and `private_subnet_ids` are wired in from the VPC unit via a Terragrunt `dependency` block.
