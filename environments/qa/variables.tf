##############################################################################
# environments/qa/variables.tf
##############################################################################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used in resource tags)"
  type        = string
}

variable "env" {
  description = "Environment identifier"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to provision NAT Gateways"
  type        = bool
  default     = true
}
variable "github_org" {
  description = "GitHub organisation that owns this repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the org prefix)"
  type        = string
}

variable "kms_key_admin_principal_arns" {
  description = "IAM principal ARNs that may administer the SOPS KMS key"
  type        = list(string)
  default     = []
}

variable "sops_user_principal_arns" {
  description = "IAM principal ARNs allowed to encrypt/decrypt with SOPS locally"
  type        = list(string)
  default     = []
}