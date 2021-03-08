# Network vars

variable "region" {
  default = "ap-southeast-2"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "env" {
  default = "test"
}

variable "rgroup" {
  default = "default"
}

variable "public_subnets_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnets_cidr" {
  default = "10.0.20.0/24"
}

# Availability zones
# Must define
variable "azones" {
}
