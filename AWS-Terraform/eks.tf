# Create AWS EKS ( Elastic Kubernetes Service )
# Using AWS EKS terraform module https://registry.terraform.io/modules/terraform-aws-modules/eks/aws

data "aws_availability_zones" "available_azs" {
  state = "available"
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  eks_admin_users_map = [
    for admin_user in var.eks_admin_users :
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"
      username = admin_user
      groups   = ["system:masters"]
    }
  ]
  worker_groups_launch_template = [
  {
    override_instance_types = var.worker_asg_instance_types
    asg_desired_capacity = var.asg_min_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
    asg_min_size = var.asg_min_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
    asg_max_size = var.asg_max_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
    kubelet_extra_args = "--node-labels=node.kubernetes.io/lifecycle=spot" # use Spot EC2 instances
    #public_ip = true
  }
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
  enable_irsa      = true
  write_kubeconfig = true

  subnets = aws_subnet.private_subnet[*].id
  vpc_id  = aws_vpc.vpc.id

  worker_groups_launch_template = local.worker_groups_launch_template
  map_users = local.eks_admin_users_map
  depends_on = [aws_subnet.private_subnet]
}

# Get cluster and cluster_auth for cert and token
data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}
data "aws_eks_cluster_auth" "cluster_auth" {
  name = module.eks_cluster.cluster_id
}

provider "kubernetes" {
  host = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token = data.aws_eks_cluster_auth.cluster_auth.token
  load_config_file = false
}

# Create service account for automated access to AWS Secrets store
# name must match eks-irsa.tf k8s_service_account_name
resource "kubernetes_service_account" "aws-eks-secrets-sa" {
  metadata {
    name = "aws-eks-secrets-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${local.aws_account_id}:role/eks-secrets-manager"
    }
  }
  automount_service_account_token = true

  depends_on = [module.iam_assumable_role_admin]
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token = data.aws_eks_cluster_auth.cluster_auth.token
    load_config_file = false
  }
}

# Spot instance termination handler chart
resource "helm_release" "spot_termination_handler" {
  name       = var.spot_term_helm_chart_name
  chart      = var.spot_term_helm_chart_name
  repository = var.spot_term_helm_chart_repo
  version    = var.spot_term_helm_chart_version
  namespace  = var.spot_term_helm_chart_namespace

  depends_on = [module.eks_cluster]
}

resource "helm_release" "aws_secret_injector" {
  name = "secret-inject"
  chart = "secret-inject"
  repository = "https://aws-samples.github.io/aws-secret-sidecar-injector/"
  namespace = "kube-system"
}

resource "aws_autoscaling_policy" "eks_autoscaling_policy" {
  count = length(local.worker_groups_launch_template)

  name = "${module.eks_cluster.workers_asg_names[count.index]}-autoscaling-policy"
  autoscaling_group_name = module.eks_cluster.workers_asg_names[count.index]
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.asg_avg_cpu
  }
}

#output "oidc_provider_arn" {
#  value = module.cluster.oidc_provider_arn
#}
