##############################################
# Add-on: Crossplane
# Instala Crossplane via Helm no cluster EKS.
##############################################

resource "helm_release" "crossplane" {
  count = var.enable_crossplane ? 1 : 0

  name             = "crossplane"
  repository       = "https://charts.crossplane.io/stable"
  chart            = "crossplane"
  namespace        = var.crossplane_namespace
  create_namespace = true
  version          = var.crossplane_chart_version
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 600

  depends_on = [module.eks]
}



##############################################
# Sincronizacao no cluster: ServiceAccount IRSA
##############################################

resource "kubernetes_manifest" "crossplane_irsa_serviceaccount" {
  count = var.enable_crossplane && var.enable_crossplane_irsa && var.enable_crossplane_irsa_serviceaccount_sync ? 1 : 0

  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = var.crossplane_irsa_service_account
      namespace = var.crossplane_irsa_namespace
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.crossplane_irsa[0].arn
      }
    }
  }

  depends_on = [
    helm_release.crossplane,
    aws_iam_role.crossplane_irsa
  ]
}

##############################################
# EnvironmentConfig do Crossplane (OIDC do cluster)
# Consumido pelas Compositions em mode: Pipeline.
##############################################

resource "kubernetes_manifest" "crossplane_environment_config" {
  count = var.enable_crossplane && var.enable_eks_oidc_provider ? 1 : 0

  manifest = {
    apiVersion = "apiextensions.crossplane.io/v1beta1"
    kind       = "EnvironmentConfig"
    metadata = {
      name = "cluster-aws-metadata"
    }
    data = {
      oidcProviderArn    = module.eks.oidc_provider_arn
      oidcIssuerHostpath = local.oidc_issuer_hostpath
    }
  }

  depends_on = [
    helm_release.crossplane,
    module.eks,
    kubernetes_manifest.crossplane_irsa_serviceaccount
  ]
}


##############################################
# IRSA do Crossplane
# Role assumida pelo ServiceAccount do provider-aws.
##############################################

resource "aws_iam_role" "crossplane_irsa" {
  count = var.enable_crossplane_irsa ? 1 : 0

  name               = var.crossplane_irsa_role_name != "" ? var.crossplane_irsa_role_name : "${var.cluster_name}-crossplane-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.crossplane_irsa_trust[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "crossplane_irsa_poweruser" {
  count = var.enable_crossplane_irsa ? 1 : 0

  role       = aws_iam_role.crossplane_irsa[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/PowerUserAccess"
}
