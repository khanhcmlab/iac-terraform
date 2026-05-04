##############################################################################
# modules/vpc/variables.tf
##############################################################################

variable "env" {
  description = "Environment name (dev | qa | prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Map of tags applied to every resource"
  type        = map(string)
  default     = {}
}
