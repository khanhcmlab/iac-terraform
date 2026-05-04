##############################################################################
# environments/dev/backend.tf
# Remote state stored in S3 with DynamoDB locking – dev workspace.
# The S3 bucket and DynamoDB table must be pre-provisioned (bootstrap).
##############################################################################

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"   # Replace with your bucket name
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"        # Replace with your table name
  }
}
