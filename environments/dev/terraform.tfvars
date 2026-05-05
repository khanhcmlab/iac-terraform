##############################################################################
# environments/dev/terraform.tfvars
# Non-sensitive, environment-specific variable values for dev.
# Sensitive values (credentials, secrets) must NEVER appear here;
# inject them via GitHub Secrets / environment variables at CI time.
##############################################################################

project_name = "iac-demo"
env          = "dev"
aws_region   = "us-east-1"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# NAT Gateway disabled in dev to reduce cost
enable_nat_gateway = false

# GitHub OIDC configuration for SOPS KMS IAM role
github_org  = "khanhcmlab"
github_repo = "iac-terraform"

# Optional: add developer/admin ARNs for local SOPS access
# kms_key_admin_principal_arns = []
# sops_user_principal_arns     = []
