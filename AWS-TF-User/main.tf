# Purpose:
#   Create necessary group, user, role and policy which can create 
#   aws infra without having to be admin permission. 
#   This purticular terraform script will be executed by admin (not root!)

#----------------------------------#
# WARNING!!! WARNING!!! WARNING!!! #
#----------------------------------#
# This will generate terraform user access key & secret
# which will be written to tfstate file
# DO NOT store tfstate file in git repo
# Guard it judiciously
#



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

# Create group policy
# This can be modified based on the infra creation requirement
# The policy json can be put into separate json file
# But IMO, inline has more readability in this case!

resource "aws_iam_policy" "terraforming_policy" {
  name  = "terraforming_policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowSpecifics",
        "Action" : [
          "lambda:*",
          "apigateway:*",
          "ec2:*",
          "rds:*",
          "secretsmanager:*",
          "s3:*",
          "sns:*",
          "states:*",
          "ssm:*",
          "sqs:*",
          "iam:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "cloudfront:*",
          "route53:*",
          "ecr:*",
          "eks:*",
          "logs:*",
          "ecs:*",
          "application-autoscaling:*",
          "logs:*",
          "events:*",
          "elasticache:*",
          "es:*",
          "kms:*",
          "dynamodb:*"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Sid" : "DenySpecifics",
        "Action" : [
          "iam:*User*",
          "iam:*Login*",
          "iam:*Group*",
          "iam:*Provider*",
          "aws-portal:*",
          "budgets:*",
          "config:*",
          "directconnect:*",
          "aws-marketplace:*",
          "aws-marketplace-management:*",
          "ec2:*ReservedInstances*"
        ],
        "Effect" : "Deny",
        "Resource" : "*"
      }
    ]
  })
}


# Create Group

resource "aws_iam_group" "terraforming" {
  name = "terraforming"
  path = "/"
}

# Attach group policy to group

resource "aws_iam_group_policy_attachment" "gp-attach" {
  group      = aws_iam_group.terraforming.name
  policy_arn = aws_iam_policy.terraforming_policy.arn
}

# Create user

resource "aws_iam_user" "terraforming_user" {
  name = "terraforming_user"
}

resource "aws_iam_access_key" "tf_user_accesskey" {
  user = aws_iam_user.terraforming_user.name
}

# Add terraforming user to the group

resource "aws_iam_user_group_membership" "tf_user_group" {
  user = aws_iam_user.terraforming_user.name

  groups = [
    aws_iam_group.terraforming.name,
  ]
}


# Output access key secret

output "secret" {
  value = aws_iam_access_key.tf_user_accesskey.encrypted_secret
}

# Create aws S3 bucket for terraform.tfstate backup
resource "aws_s3_bucket" "store-terraform-state" {
    bucket = var.s3-bucket-tfstate-store
    acl = "private"

    versioning {
        enabled = true
    }

    tags = {
        env = var.env
        resource_group = var.rgroup
    }
}

# Create dynamodb table for tfstate locking
resource "aws_dynamodb_table" "dynamodb-tfstate-lock" {
    name           = "${var.env}-dynamodb-tfstate-lock"
    hash_key       = "LockID"
    read_capacity  = 20
    write_capacity = 20

    attribute {
        name = "LockID"
        type = "S"
    }

    tags = {
        env = var.env
        resource_group = var.rgroup
    }
}

# Create aws secretmanager secret for rds taskdb password

resource "aws_secretsmanager_secret" "pg_taskdb_secret" {
  name = "pg_taskdb_secret"
}
resource "aws_secretsmanager_secret_version" "pg_taskdb_version" {
  secret_id     = aws_secretsmanager_secret.pg_taskdb_secret.id
  secret_string = var.pg_taskdb_password
}
