# Create AWS EKS ( Elastic Kubernetes Service )
# Using AWS EKS terraform module https://registry.terraform.io/modules/terraform-aws-modules/eks/aws

data "aws_availability_zones" "available_azs" {
  state = "available"
}

locals {
  worker_groups_launch_template = [
  {
    override_instance_types = var.worker_asg_instance_types
    asg_desired_capacity = var.asg_min_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
    asg_min_size = var.asg_min_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
    asg_max_size = var.asg_max_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
    kubelet_extra_args = "--node-labels=node.kubernetes.io/lifecycle=spot" # use Spot EC2 instances
    #public_ip = true
  },
  ]
}

# Create IAM role for EKS to access other AWS Services

resource "aws_iam_role" "eks_iam_role" {
  name = "eks_iam_role"

  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "eks_iam_role_policy_attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy", 
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  role       = aws_iam_role.eks_iam_role.name
  policy_arn = each.value
}

# Create EKS cluster
module "eks_cluster" {
  source           = "terraform-aws-modules/eks/aws"
  version          = "12.1.0"
  cluster_name     = var.eks_cluster_name
  cluster_version  = var.eks_cluster_version
  write_kubeconfig = true

  subnets = aws_subnet.private_subnets.tags["Name"]
  vpc_id  = aws_vpc.vpc.id

  worker_groups_launch_template = local.worker_groups_launch_template
}
