##############################################################################
# modules/kms_sops/outputs.tf
##############################################################################

output "kms_key_arn" {
  description = "ARN of the SOPS KMS Customer Managed Key"
  value       = aws_kms_key.sops.arn
}

output "kms_key_id" {
  description = "Key ID of the SOPS KMS Customer Managed Key"
  value       = aws_kms_key.sops.key_id
}

output "kms_alias_arn" {
  description = "ARN of the KMS alias"
  value       = aws_kms_alias.sops.arn
}

output "kms_alias_name" {
  description = "Name of the KMS alias (stable reference for .sops.yaml)"
  value       = aws_kms_alias.sops.name
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role for this environment"
  value       = aws_iam_role.github_actions.arn
}
