##############################################
# Outputs principais do cluster
##############################################

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
}

output "cluster_ca" {
  value       = module.eks.cluster_ca
  description = "EKS cluster CA data (base64)"
}

output "cluster_oidc_issuer" {
  value       = module.eks.cluster_oidc_issuer
  description = "EKS OIDC issuer URL"
}

output "nodegroup_name" {
  value       = module.eks.nodegroup_name
  description = "EKS node group name"
}

output "vpc_id" {
  value       = module.eks.vpc_id
  description = "VPC ID used by EKS"
}

output "subnet_ids" {
  value       = module.eks.subnet_ids
  description = "Subnet IDs used by EKS"
}

output "kms_key_arn" {
  value       = module.eks.kms_key_arn
  description = "KMS key ARN used for EKS secrets encryption"
}

##############################################
# Outputs de integracoes
##############################################

output "crossplane_irsa_role_arn" {
  value       = module.addons.crossplane_irsa_role_arn
  description = "IAM role ARN to annotate in the Crossplane provider ServiceAccount"
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN used by IRSA"
}

output "external_secrets_release_name" {
  value       = module.addons.external_secrets_release_name
  description = "Helm release name for external-secrets"
}

output "external_secrets_irsa_role_arn" {
  value       = module.addons.external_secrets_irsa_role_arn
  description = "IAM role ARN used by external-secrets ServiceAccount IRSA"
}

output "crossplane_release_name" {
  value       = module.addons.crossplane_release_name
  description = "Helm release name for crossplane"
}

output "cluster_metadata_ssm_base_path" {
  value       = var.enable_cluster_metadata_ssm ? "/${trim(var.cluster_metadata_ssm_prefix, "/")}/${var.cluster_name}" : null
  description = "Base SSM path used to store cluster metadata"
}

output "argocd_release_name" {
  value       = module.addons.argocd_release_name
  description = "Helm release name for Argo CD (when enabled via Terraform)"
}

output "ingress_nginx_release_name" {
  value       = module.addons.ingress_nginx_release_name
  description = "Helm release name for ingress-nginx (when enabled via Terraform)"
}

output "kyverno_release_name" {
  value       = module.addons.kyverno_release_name
  description = "Helm release name for Kyverno (when enabled via Terraform)"
}
