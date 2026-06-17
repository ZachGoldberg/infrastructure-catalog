# VPC for EKS

Dedicated VPC for an EKS cluster. Provisions public + private subnets across 3 AZs, NAT gateway(s), and the subnet tags the AWS Load Balancer Controller needs for discovery.

- Worker nodes and pods run in the **private** subnets.
- Internet-facing load balancers and NAT gateways live in the **public** subnets.
- `single_nat_gateway = true` (default) is cost-sensible for dev. Set `false` for one NAT gateway per AZ in production.

Outputs `vpc_id` and `private_subnets` are consumed by the EKS unit via a Terragrunt `dependency` block.
