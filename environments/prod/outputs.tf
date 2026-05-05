##############################################################################
# environments/prod/outputs.tf
##############################################################################

output "vpc_id" {
  description = "VPC ID for the prod environment"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for the prod environment"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs for the prod environment"
  value       = module.vpc.private_subnet_ids
}

output "sops_kms_key_arn" {
  description = "ARN of the prod SOPS KMS key"
  value       = module.kms_sops.kms_key_arn
}

output "sops_kms_alias_name" {
  description = "KMS alias name – paste into .sops.yaml"
  value       = module.kms_sops.kms_alias_name
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions (prod)"
  value       = module.kms_sops.github_actions_role_arn
}
