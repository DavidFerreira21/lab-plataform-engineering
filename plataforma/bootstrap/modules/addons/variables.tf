variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_oidc_issuer" {
  type        = string
  description = "EKS OIDC issuer URL"
}

variable "oidc_provider_arn" {
  type        = string
  description = "IAM OIDC provider ARN used by IRSA"
  default     = null
}

variable "cluster_vpc_id" {
  type        = string
  description = "VPC ID where EKS cluster is running"
}

variable "enable_eks_oidc_provider" {
  type        = bool
  description = "Whether EKS OIDC provider is enabled"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to addon-managed IAM resources"
  default     = {}
}

variable "cluster_metadata_ssm_prefix" {
  type        = string
  description = "Base path prefix for cluster metadata parameters in SSM"
}

variable "enable_crossplane" {
  type        = bool
  description = "Install Crossplane via Helm"
}

variable "crossplane_namespace" {
  type        = string
  description = "Namespace for Crossplane Helm release"
}

variable "crossplane_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Crossplane"
}

variable "crossplane_environment_config_api_version" {
  type        = string
  description = "API version used for Crossplane EnvironmentConfig"
}

variable "enable_crossplane_irsa" {
  type        = bool
  description = "Create IRSA resources for Crossplane provider-aws"
}

variable "crossplane_irsa_namespace" {
  type        = string
  description = "Namespace of the Crossplane provider ServiceAccount used for IRSA"
}

variable "crossplane_irsa_service_account" {
  type        = string
  description = "ServiceAccount name of the Crossplane provider used for IRSA"
}

variable "crossplane_irsa_role_name" {
  type        = string
  description = "IAM role name for Crossplane IRSA"
}

variable "enable_crossplane_irsa_serviceaccount_sync" {
  type        = bool
  description = "Manage Crossplane ServiceAccount annotation with IRSA role ARN"
}

variable "enable_crossplane_irsa_iam_full_access" {
  type        = bool
  description = "Attach IAMFullAccess to Crossplane IRSA role (lab-friendly; use least privilege in production)"
  default     = true
}

variable "enable_external_secrets" {
  type        = bool
  description = "Install external-secrets via Helm"
}

variable "external_secrets_namespace" {
  type        = string
  description = "Namespace for external-secrets Helm release"
}

variable "external_secrets_chart_version" {
  type        = string
  description = "Pinned Helm chart version for external-secrets"
}

variable "enable_external_secrets_irsa" {
  type        = bool
  description = "Create IRSA resources for external-secrets"
}

variable "external_secrets_irsa_service_account" {
  type        = string
  description = "ServiceAccount name used by external-secrets controller for IRSA"
}

variable "external_secrets_irsa_role_name" {
  type        = string
  description = "IAM role name for external-secrets IRSA"
}

variable "enable_argocd" {
  type        = bool
  description = "Install Argo CD via Helm"
  default     = false
}

variable "argocd_namespace" {
  type        = string
  description = "Namespace for Argo CD Helm release"
  default     = "argocd"
}

variable "argocd_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Argo CD"
  default     = "7.8.6"
}

variable "enable_ingress_nginx" {
  type        = bool
  description = "Install ingress-nginx via Helm"
  default     = false
}

variable "ingress_nginx_namespace" {
  type        = string
  description = "Namespace for ingress-nginx Helm release"
  default     = "ingress-nginx"
}

variable "ingress_nginx_chart_version" {
  type        = string
  description = "Pinned Helm chart version for ingress-nginx"
  default     = "4.12.0"
}

variable "enable_kyverno" {
  type        = bool
  description = "Install Kyverno via Helm"
  default     = false
}

variable "kyverno_namespace" {
  type        = string
  description = "Namespace for Kyverno Helm release"
  default     = "kyverno"
}

variable "kyverno_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Kyverno"
  default     = "3.3.4"
}
