##############################################################################
# environments/prod/backend.tf
##############################################################################

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"   # Replace with your bucket name
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"        # Replace with your table name
  }
}
