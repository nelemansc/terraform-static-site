provider "aws" {
  region  = var.aws_region
  profile = "personal"
}

terraform {
  backend "s3" {
    profile        = "personal"
    bucket         = "cassidy-tfstate"
    dynamodb_table = "terraform-dynamodb-table"
    region         = "us-east-1"
    key            = "s3/cassidynelemans.com/terraform.tfstate"
  }
}
