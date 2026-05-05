##############################################################################
# environments/prod/terraform.tfvars
##############################################################################

project_name = "iac-demo"
env          = "prod"
aws_region   = "us-east-1"

vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]

# NAT Gateway required in prod for private subnet egress
enable_nat_gateway = true

# GitHub OIDC configuration for SOPS KMS IAM role
github_org  = "khanhcmlab"
github_repo = "iac-terraform"

# Optional: add developer/admin ARNs for local SOPS access
# kms_key_admin_principal_arns = []
# sops_user_principal_arns     = []
