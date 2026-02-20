output "crossplane_release_name" {
  value       = var.enable_crossplane ? helm_release.crossplane[0].name : null
  description = "Helm release name for crossplane"
}

output "crossplane_irsa_role_arn" {
  value       = var.enable_crossplane_irsa ? aws_iam_role.crossplane_irsa[0].arn : null
  description = "IAM role ARN used by Crossplane ServiceAccount IRSA"
}

output "external_secrets_release_name" {
  value       = var.enable_external_secrets ? helm_release.external_secrets[0].name : null
  description = "Helm release name for external-secrets"
}

output "external_secrets_irsa_role_arn" {
  value       = var.enable_external_secrets && var.enable_external_secrets_irsa ? aws_iam_role.external_secrets_irsa[0].arn : null
  description = "IAM role ARN used by external-secrets ServiceAccount IRSA"
}

output "argocd_release_name" {
  value       = var.enable_argocd ? helm_release.argocd[0].name : null
  description = "Helm release name for Argo CD"
}

output "ingress_nginx_release_name" {
  value       = var.enable_ingress_nginx ? helm_release.ingress_nginx[0].name : null
  description = "Helm release name for ingress-nginx"
}
