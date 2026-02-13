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
  value       = var.enable_crossplane_irsa ? aws_iam_role.crossplane_irsa[0].arn : null
  description = "IAM role ARN to annotate in the Crossplane provider ServiceAccount"
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN used by IRSA"
}

output "external_secrets_release_name" {
  value       = var.enable_external_secrets ? helm_release.external_secrets[0].name : null
  description = "Helm release name for external-secrets"
}

output "external_secrets_irsa_role_arn" {
  value       = var.enable_external_secrets && var.enable_external_secrets_irsa ? aws_iam_role.external_secrets_irsa[0].arn : null
  description = "IAM role ARN used by external-secrets ServiceAccount IRSA"
}

output "crossplane_release_name" {
  value       = var.enable_crossplane ? helm_release.crossplane[0].name : null
  description = "Helm release name for crossplane"
}

output "cluster_metadata_ssm_base_path" {
  value       = var.enable_cluster_metadata_ssm ? "/${trim(var.cluster_metadata_ssm_prefix, "/")}/${var.cluster_name}" : null
  description = "Base SSM path used to store cluster metadata"
}
