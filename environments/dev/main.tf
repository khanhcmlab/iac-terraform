##############################################################################
# environments/dev/main.tf
##############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  common_tags          = local.common_tags
}

module "kms_sops" {
  source = "../../modules/kms_sops"

  env          = var.env
  project_name = var.project_name
  common_tags  = local.common_tags

  github_org         = var.github_org
  github_repo        = var.github_repo
  github_environment = var.env # GitHub Environment name matches env

  key_administrator_principal_arns = var.kms_key_admin_principal_arns
  sops_user_principal_arns         = var.sops_user_principal_arns
}
