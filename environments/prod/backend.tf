##############################################################################
# environments/prod/backend.tf
##############################################################################

terraform {
  backend "s3" {
    bucket         = "khanhcmlab-prod-state-bucket"   # Replace with your bucket name
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "khanhcmlab-prod-state-lock"        # Replace with your table name
  }
}
