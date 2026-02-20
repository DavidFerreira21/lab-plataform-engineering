##############################################
# Add-on: Crossplane
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

resource "aws_iam_role_policy_attachment" "crossplane_irsa_iam_full_access" {
  count = var.enable_crossplane_irsa && var.enable_crossplane_irsa_iam_full_access ? 1 : 0

  role       = aws_iam_role.crossplane_irsa[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/IAMFullAccess"
}

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
}

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

resource "kubernetes_manifest" "crossplane_environment_config" {
  count = var.enable_crossplane && var.enable_eks_oidc_provider ? 1 : 0

  manifest = {
    apiVersion = var.crossplane_environment_config_api_version
    kind       = "EnvironmentConfig"
    metadata = {
      name = "cluster-aws-metadata"
    }
    data = {
      accountId          = data.aws_caller_identity.current.account_id
      oidcProviderArn    = var.oidc_provider_arn
      oidcIssuerHostpath = local.oidc_issuer_hostpath
    }
  }

  depends_on = [
    helm_release.crossplane,
    kubernetes_manifest.crossplane_irsa_serviceaccount
  ]
}

##############################################
# Add-on: External Secrets
##############################################

resource "aws_iam_role" "external_secrets_irsa" {
  count = var.enable_external_secrets && var.enable_external_secrets_irsa ? 1 : 0

  name               = var.external_secrets_irsa_role_name != "" ? var.external_secrets_irsa_role_name : "${var.cluster_name}-external-secrets-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_irsa_trust[0].json
  tags               = var.tags
}

resource "aws_iam_policy" "external_secrets_ssm_read" {
  count = var.enable_external_secrets && var.enable_external_secrets_irsa ? 1 : 0

  name   = "${var.cluster_name}-external-secrets-ssm-read"
  policy = data.aws_iam_policy_document.external_secrets_ssm_read[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "external_secrets_irsa_ssm_read" {
  count = var.enable_external_secrets && var.enable_external_secrets_irsa ? 1 : 0

  role       = aws_iam_role.external_secrets_irsa[0].name
  policy_arn = aws_iam_policy.external_secrets_ssm_read[0].arn
}

resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = var.external_secrets_namespace
  create_namespace = true
  version          = var.external_secrets_chart_version
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 600

  values = [
    yamlencode(merge(
      {
        installCRDs = true
      },
      var.enable_external_secrets_irsa ? {
        serviceAccount = {
          create = true
          name   = var.external_secrets_irsa_service_account
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets_irsa[0].arn
          }
        }
      } : {}
    ))
  ]

  depends_on = [aws_iam_role_policy_attachment.external_secrets_irsa_ssm_read]
}

##############################################
# Add-on: Argo CD
##############################################

resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.argocd_namespace
  create_namespace = true
  version          = var.argocd_chart_version
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 600
}

##############################################
# Add-on: ingress-nginx
##############################################

resource "helm_release" "ingress_nginx" {
  count = var.enable_ingress_nginx ? 1 : 0

  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = var.ingress_nginx_namespace
  create_namespace = true
  version          = var.ingress_nginx_chart_version
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 600

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]
}
