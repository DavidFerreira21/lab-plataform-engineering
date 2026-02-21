##############################################
# Modulo de Add-ons (Crossplane / External Secrets / Argo CD)
##############################################

module "addons" {
  source = "./modules/addons"

  cluster_name        = module.eks.cluster_name
  cluster_oidc_issuer = module.eks.cluster_oidc_issuer
  oidc_provider_arn   = module.eks.oidc_provider_arn
  cluster_vpc_id      = module.eks.vpc_id

  enable_eks_oidc_provider    = var.enable_eks_oidc_provider
  aws_region                  = var.aws_region
  tags                        = var.tags
  cluster_metadata_ssm_prefix = var.cluster_metadata_ssm_prefix

  enable_crossplane                          = var.enable_crossplane
  crossplane_namespace                       = var.crossplane_namespace
  crossplane_chart_version                   = var.crossplane_chart_version
  crossplane_environment_config_api_version  = var.crossplane_environment_config_api_version
  enable_crossplane_irsa                     = var.enable_crossplane_irsa
  crossplane_irsa_namespace                  = var.crossplane_irsa_namespace
  crossplane_irsa_service_account            = var.crossplane_irsa_service_account
  crossplane_irsa_role_name                  = var.crossplane_irsa_role_name
  enable_crossplane_irsa_serviceaccount_sync = var.enable_crossplane_irsa_serviceaccount_sync
  enable_crossplane_irsa_iam_full_access     = var.enable_crossplane_irsa_iam_full_access

  enable_external_secrets               = var.enable_external_secrets
  external_secrets_namespace            = var.external_secrets_namespace
  external_secrets_chart_version        = var.external_secrets_chart_version
  enable_external_secrets_irsa          = var.enable_external_secrets_irsa
  external_secrets_irsa_service_account = var.external_secrets_irsa_service_account
  external_secrets_irsa_role_name       = var.external_secrets_irsa_role_name

  enable_argocd        = var.enable_argocd
  argocd_namespace     = var.argocd_namespace
  argocd_chart_version = var.argocd_chart_version

  enable_ingress_nginx        = var.enable_ingress_nginx
  ingress_nginx_namespace     = var.ingress_nginx_namespace
  ingress_nginx_chart_version = var.ingress_nginx_chart_version

  enable_kyverno        = var.enable_kyverno
  kyverno_namespace     = var.kyverno_namespace
  kyverno_chart_version = var.kyverno_chart_version

  depends_on = [module.eks]
}
