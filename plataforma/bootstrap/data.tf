##############################################
# Data sources: rede (VPC/Subnets)
##############################################

# Valores efetivos para VPC e subnets usados no modulo EKS.
locals {
  effective_vpc_id     = var.use_default_vpc ? data.aws_vpc.default[0].id : var.vpc_id
  effective_subnet_ids = var.use_default_vpc ? data.aws_subnets.default_vpc[0].ids : var.subnet_ids
}

data "aws_vpc" "default" {
  count   = var.use_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default_vpc" {
  count = var.use_default_vpc ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }

  filter {
    name   = "availability-zone"
    values = var.allowed_azs
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

##############################################
# Data sources: AWS/OIDC para IRSA
##############################################

locals {
  oidc_issuer_hostpath    = replace(module.eks.cluster_oidc_issuer, "https://", "")
  crossplane_irsa_subject = format("system:serviceaccount:%s:%s", var.crossplane_irsa_namespace, var.crossplane_irsa_service_account)
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
      identifiers = [module.eks.oidc_provider_arn]
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
        local.crossplane_irsa_subject,
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
      identifiers = [module.eks.oidc_provider_arn]
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
