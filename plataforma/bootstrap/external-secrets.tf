##############################################
# Add-on: External Secrets
# Instala chart Helm e CRDs no cluster EKS.
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

  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.external_secrets_irsa_ssm_read
  ]
}
