terraform {
  required_version = ">= 0.14"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    kubernetes = {
      version = "~> 1.9"
    }
    helm = {
      version = "~> 1.2"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-2"
}

terraform {
  backend "s3" {}
}

data "aws_caller_identity" "current" {} # current user Account ID and ARN

# The var.tf_state_bucket is provided at 
# `terraform init` invocation.
# e.g. 
#   terraform init \ 
#
#data "terraform_remote_state" "state" {
#  backend = "s3"
  #config {
    #bucket = "${var.tf_state_bucket}"
    #lock_table = "${var.tf_state_table}"
    #region = "${var.region}"
    #key = "${var.key}"
  #}
#}
