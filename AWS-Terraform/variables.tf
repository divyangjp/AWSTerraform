##############################################################################
# Variables File
#
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "region" {
  default = "ap-southeast-2"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "env" {
  default = "dev"
}

variable "rgroup" {
  default = "rg_dev"
}

variable "public_subnets_cidr" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets_cidr" {
  default = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

# EKS cluster related variables

variable "eks_cluster_name" {
  default = "eksdev"
}
variable "eks_cluster_version" {
  default = "1.18"
}

variable "worker_asg_instance_types" {
  type = list(string)
  description = "EKS EC2 Instance types"
  default = ["t3.small", "t2.small"]
}
variable "asg_min_size_by_az" {
  type = number
  description = "Minimum number of EC2 instances on each AZ."
  default = 1
}
variable "asg_max_size_by_az" {
  type = number
  description = "Maximum number of EC2 instances on each AZ."
  default = 3
}
variable "asg_avg_cpu" {
  default = 50
}
variable "spot_term_helm_chart_name" {
  default = "aws-node-termination-handler"
}
variable "spot_term_helm_chart_repo" {
  default = "https://aws.github.io/eks-charts"
}
variable "spot_term_helm_chart_version" {
  default = "0.11.0"
}
variable "spot_term_helm_chart_namespace" {
  default = "kube-system"
}
