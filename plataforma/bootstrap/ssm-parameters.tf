##############################################
# Metadados do cluster no SSM Parameter Store
# Base para automacao futura de IRSA via Crossplane.
##############################################

locals {
  cluster_metadata_ssm_base_path = "${trim(var.cluster_metadata_ssm_prefix, "/")}/${var.cluster_name}"
}

resource "aws_ssm_parameter" "cluster_name" {
  count = var.enable_cluster_metadata_ssm ? 1 : 0

  name  = "/${local.cluster_metadata_ssm_base_path}/cluster/name"
  type  = "String"
  value = module.eks.cluster_name
  tags  = var.tags
}

resource "aws_ssm_parameter" "cluster_region" {
  count = var.enable_cluster_metadata_ssm ? 1 : 0

  name  = "/${local.cluster_metadata_ssm_base_path}/cluster/region"
  type  = "String"
  value = var.aws_region
  tags  = var.tags
}

resource "aws_ssm_parameter" "oidc_issuer_url" {
  count = var.enable_cluster_metadata_ssm ? 1 : 0

  name  = "/${local.cluster_metadata_ssm_base_path}/oidc/issuer_url"
  type  = "String"
  value = module.eks.cluster_oidc_issuer
  tags  = var.tags
}

resource "aws_ssm_parameter" "oidc_issuer_hostpath" {
  count = var.enable_cluster_metadata_ssm ? 1 : 0

  name  = "/${local.cluster_metadata_ssm_base_path}/oidc/issuer_hostpath"
  type  = "String"
  value = replace(module.eks.cluster_oidc_issuer, "https://", "")
  tags  = var.tags
}

resource "aws_ssm_parameter" "oidc_audience" {
  count = var.enable_cluster_metadata_ssm ? 1 : 0

  name  = "/${local.cluster_metadata_ssm_base_path}/oidc/audience"
  type  = "String"
  value = "sts.amazonaws.com"
  tags  = var.tags
}

resource "aws_ssm_parameter" "oidc_provider_arn" {
  count = var.enable_cluster_metadata_ssm && var.enable_eks_oidc_provider ? 1 : 0

  name  = "/${local.cluster_metadata_ssm_base_path}/oidc/provider_arn"
  type  = "String"
  value = module.eks.oidc_provider_arn
  tags  = var.tags
}

resource "aws_ssm_parameter" "account_id" {
  count = var.enable_cluster_metadata_ssm ? 1 : 0

  name  = "/${local.cluster_metadata_ssm_base_path}/account/id"
  type  = "String"
  value = data.aws_caller_identity.current.account_id
  tags  = var.tags
}
