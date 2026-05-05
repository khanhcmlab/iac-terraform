##############################################################################
# environments/qa/outputs.tf
##############################################################################

output "vpc_id" {
  description = "VPC ID for the qa environment"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for the qa environment"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs for the qa environment"
  value       = module.vpc.private_subnet_ids
}
