##############################################################################
# modules/kms_sops/variables.tf
##############################################################################

variable "env" {
  description = "Environment identifier – must match the GitHub Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "github_org" {
  description = "GitHub organisation or username that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the org/ prefix)"
  type        = string
}

variable "github_environment" {
  description = "GitHub Environment name whose OIDC tokens may assume the CI role"
  type        = string
}

variable "github_allowed_workflow_refs" {
  description = <<-EOT
    Optional list of reusable-workflow refs allowed to assume the role.
    Example: ["octo-org/octo-automation/.github/workflows/oidc.yml@refs/heads/main"]
    Omit to allow any workflow within the repository.
  EOT
  type        = list(string)
  default     = []
}

variable "key_administrator_principal_arns" {
  description = "Additional IAM principal ARNs (roles/users) that may administer the KMS key"
  type        = list(string)
  default     = []
}

variable "sops_user_principal_arns" {
  description = <<-EOT
    IAM principal ARNs (developers / automation) that need local SOPS
    encrypt AND decrypt access to this key.
    Keep this empty unless developer machines require direct KMS access.
  EOT
  type        = list(string)
  default     = []
}

variable "ci_role_name" {
  description = "Override for the GitHub Actions IAM role name; defaults to <project>-github-actions-<env>"
  type        = string
  default     = null
}

variable "kms_alias_name" {
  description = "Override for the KMS alias name; defaults to alias/<project>/sops/<env>"
  type        = string
  default     = null
}

variable "enable_key_rotation" {
  description = "Enable automatic annual KMS key rotation"
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "Number of days to wait before key deletion (7–30)"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
