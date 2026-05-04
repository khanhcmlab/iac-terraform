##############################################################################
# environments/qa/backend.tf
##############################################################################

terraform {
  backend "s3" {
    bucket         = "khanhcmlab-qa-state-bucket" # Replace with your bucket name
    key            = "qa/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "khanhcmlab-qa-state-lock" # Replace with your table name
  }
}
