##############################################################################
# environments/dev/outputs.tf
##############################################################################

output "vpc_id" {
  description = "VPC ID for the dev environment"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for the dev environment"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs for the dev environment"
  value       = module.vpc.private_subnet_ids
}
