terraform {
  required_version = ">= 0.14"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-2"
}

terraform {
     backend "s3" {
         encrypt = true
         bucket = "continotest-terraform-state"
         dynamodb_table = "continotest-dynamodb-tfstate-lock"
         region = "ap-southeast-2"
         key = "ctest/terraform.tfstate"
     }
}
