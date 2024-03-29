variable "env" {
  default = "dev"
}

variable s3-bucket-tfstate-store {
  # NO DEFAULT
  # Must provide unique s3 bucket name to be created
}

variable "rgroup" {
  default = "rg_dev"
}
