##############################################################################
# modules/kms_sops/main.tf
#
# Creates per-environment resources needed for SOPS secret management:
#   - AWS KMS Customer Managed Key with automatic rotation
#   - KMS Alias for stable reference in .sops.yaml
#   - IAM Role for GitHub Actions (OIDC) with least-privilege decrypt-only
#     access scoped to this environment's key
#   - IAM Key Policy that prevents other environments from decrypting
##############################################################################

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  ci_role_name         = coalesce(var.ci_role_name, "${var.project_name}-github-actions-${var.env}")
  kms_alias_name       = coalesce(var.kms_alias_name, "alias/${var.project_name}/sops/${var.env}")
  github_oidc_provider = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  github_subject       = "repo:${var.github_org}/${var.github_repo}:environment:${var.github_environment}"

  # Always include the account root so key management is never locked out.
  key_admin_principals = distinct(
    concat(
      ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"],
      var.key_administrator_principal_arns
    )
  )

  kms_decrypt_actions = ["kms:Decrypt", "kms:DescribeKey"]
  kms_encrypt_actions = [
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:DescribeKey",
    "kms:GenerateDataKey",
    "kms:GenerateDataKeyWithoutPlaintext",
    "kms:ReEncryptFrom",
    "kms:ReEncryptTo",
  ]
}

# ── GitHub Actions OIDC trust policy ────────────────────────────────────────

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid     = "GitHubActionsOidcAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider]
    }

    # The OIDC audience MUST be sts.amazonaws.com when using aws-actions/configure-aws-credentials v4.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Pin the subject to the specific GitHub Environment so only the
    # matching environment's job can assume this role.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_subject]
    }

    # Belt-and-braces: also constrain by repository so forks are rejected.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = ["${var.github_org}/${var.github_repo}"]
    }

    # Optional: lock down to specific reusable workflow refs.
    dynamic "condition" {
      for_each = length(var.github_allowed_workflow_refs) == 0 ? [] : [1]

      content {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:job_workflow_ref"
        values   = var.github_allowed_workflow_refs
      }
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = local.ci_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = merge(var.common_tags, {
    Name = local.ci_role_name
  })
}

# ── KMS key policy ───────────────────────────────────────────────────────────

data "aws_iam_policy_document" "kms_key" {
  # Root + explicit admins retain full control (prevents lock-out).
  statement {
    sid    = "AllowKeyAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.key_admin_principals
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # CI role is allowed ONLY decrypt – it cannot re-encrypt or create new
  # ciphertext, eliminating secret tampering risk from CI.
  statement {
    sid    = "AllowGitHubActionsDecrypt"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.github_actions.arn]
    }

    actions   = local.kms_decrypt_actions
    resources = ["*"]
  }

  # Optional developer IAM principals that need local SOPS encrypt/decrypt.
  dynamic "statement" {
    for_each = length(var.sops_user_principal_arns) == 0 ? [] : [1]

    content {
      sid    = "AllowSopsUsersEncryptDecrypt"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = distinct(var.sops_user_principal_arns)
      }

      actions   = local.kms_encrypt_actions
      resources = ["*"]
    }
  }
}

# ── KMS Customer Managed Key ─────────────────────────────────────────────────

resource "aws_kms_key" "sops" {
  description             = "SOPS encryption key – ${var.project_name} ${var.env}"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = data.aws_iam_policy_document.kms_key.json

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.env}-sops"
    Purpose = "sops"
  })
}

resource "aws_kms_alias" "sops" {
  name          = local.kms_alias_name
  target_key_id = aws_kms_key.sops.key_id
}

# ── Inline role policy – resource-scoped decrypt-only ───────────────────────
# Granting only the KMS operations the CI role genuinely requires.

data "aws_iam_policy_document" "github_actions_kms_access" {
  statement {
    sid    = "AllowDecryptSpecificSopsKey"
    effect = "Allow"

    actions   = local.kms_decrypt_actions
    resources = [aws_kms_key.sops.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_kms_access" {
  name   = "${local.ci_role_name}-kms-access"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_kms_access.json
}
