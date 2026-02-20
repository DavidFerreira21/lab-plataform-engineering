##############################################
# Data sources e locals dos add-ons
##############################################

locals {
  oidc_issuer_hostpath = replace(var.cluster_oidc_issuer, "https://", "")
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "crossplane_irsa_trust" {
  count = var.enable_crossplane_irsa && var.enable_eks_oidc_provider ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_issuer_hostpath}:sub"
      values = [
        "system:serviceaccount:${var.crossplane_irsa_namespace}:${var.crossplane_irsa_service_account}",
        "system:serviceaccount:${var.crossplane_irsa_namespace}:provider-aws*",
        "system:serviceaccount:${var.crossplane_irsa_namespace}:upbound-provider-family-aws*"
      ]
    }
  }
}

data "aws_iam_policy_document" "external_secrets_irsa_trust" {
  count = var.enable_external_secrets && var.enable_external_secrets_irsa && var.enable_eks_oidc_provider ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:sub"
      values   = ["system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_irsa_service_account}"]
    }
  }
}

data "aws_iam_policy_document" "external_secrets_ssm_read" {
  count = var.enable_external_secrets && var.enable_external_secrets_irsa ? 1 : 0

  statement {
    sid    = "ReadClusterMetadataParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${trim(var.cluster_metadata_ssm_prefix, "/")}/${var.cluster_name}/*"
    ]
  }
}
