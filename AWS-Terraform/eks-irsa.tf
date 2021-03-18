locals {
  k8s_service_account_namespace = "default"
  k8s_service_account_name      = "aws-eks-secrets-sa"
}

module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "eks-secrets-manager"
  provider_url                  = replace(module.eks_cluster.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.eks-secrets-manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]

  depends_on = [module.eks_cluster]
}

resource "aws_iam_policy" "eks-secrets-manager" {
  name_prefix = "eks-secrets-manager"
  description = "EKS secrets manager policy for cluster ${module.eks_cluster.cluster_id}"
  policy      = data.aws_iam_policy_document.eks-secrets-manager.json
}

data "aws_iam_policy_document" "eks-secrets-manager" {
  statement {
    sid    = "secretStoreAll"
    effect = "Allow"

    actions = [
      "secretsmanager:*",
    ]

    resources = ["*"]
  }
}
