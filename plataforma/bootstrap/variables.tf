##############################################
# Configuracao global
##############################################

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "eks-dev"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.35"
}

variable "allowed_azs" {
  type        = list(string)
  description = "Allowed AZs for selecting subnets when use_default_vpc is true"
  default     = ["us-east-1a", "us-east-1b"]
}

##############################################
# Rede
##############################################

variable "use_default_vpc" {
  type        = bool
  description = "When true use default VPC + subnets filtered by allowed_azs; when false require vpc_id and subnet_ids"
  default     = true
}

variable "vpc_id" {
  type        = string
  description = "Custom VPC ID used when use_default_vpc is false"
  default     = null
  validation {
    condition     = var.use_default_vpc || (var.vpc_id != null && trim(var.vpc_id) != "")
    error_message = "vpc_id is required when use_default_vpc is false."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Custom subnet IDs used when use_default_vpc is false"
  default     = null
  validation {
    condition     = var.use_default_vpc || (var.subnet_ids != null && length(var.subnet_ids) >= 2)
    error_message = "subnet_ids with at least 2 entries is required when use_default_vpc is false."
  }
}

variable "cluster_security_group_ids" {
  type        = list(string)
  description = "Additional security group IDs for the EKS control plane"
  default     = null
}

##############################################
# Node group
##############################################

variable "nodegroup_name" {
  type        = string
  description = "Managed node group name"
  default     = "tools"
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types for the node group"
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type        = number
  description = "Node group min size"
  default     = 2
}

variable "node_max_size" {
  type        = number
  description = "Node group max size"
  default     = 2
}

variable "node_desired_size" {
  type        = number
  description = "Node group desired size"
  default     = 2
}

variable "node_disk_size" {
  type        = number
  description = "Node group disk size (GiB)"
  default     = 20
}

variable "node_capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
}

variable "node_labels" {
  type        = map(string)
  description = "Labels for nodes"
  default     = { workload = "tools" }
}

variable "node_taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  description = "Taints for nodes"
  default     = []
}

##############################################
# IAM e acesso ao cluster
##############################################

variable "cluster_role_name" {
  type        = string
  description = "IAM role name for EKS control plane"
  default     = "eks-cluster-role"
}

variable "node_role_name" {
  type        = string
  description = "IAM role name for EKS nodes"
  default     = "eks-node-role"
}

variable "endpoint_public_access" {
  type        = bool
  description = "Expose EKS public endpoint"
  default     = true
}

variable "endpoint_private_access" {
  type        = bool
  description = "Expose EKS private endpoint"
  default     = false
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access the public EKS endpoint"
  default     = []
}

variable "cluster_log_types" {
  type        = list(string)
  description = "EKS control plane log types"
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_encryption" {
  type        = bool
  description = "Enable secrets encryption with KMS"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to EKS resources"
  default     = {}
}

variable "update_max_unavailable" {
  type        = number
  description = "Max unavailable nodes during node group update"
  default     = 1
}

variable "update_max_unavailable_percentage" {
  type        = number
  description = "Max unavailable percentage during node group update"
  default     = null
}

variable "enable_addons" {
  type        = bool
  description = "Enable managed EKS addons (vpc-cni, coredns, kube-proxy)"
  default     = true
}

variable "addon_versions" {
  type        = map(string)
  description = "Addon versions by name (vpc-cni, coredns, kube-proxy)"
  default     = {}
}

variable "enable_cluster_creator_admin" {
  type        = bool
  description = "Grant cluster admin to the Terraform caller"
  default     = true
}

variable "cluster_creator_arn" {
  type        = string
  description = "Principal ARN to receive cluster admin access (default: Terraform caller)"
  default     = null
}

variable "access_entries" {
  type = list(object({
    principal_arn = string
    policy_arn    = string
    scope_type    = optional(string, "cluster")
    namespaces    = optional(list(string), [])
  }))
  description = "Additional EKS access entries"
  default     = []
}

##############################################
# OIDC para IRSA
##############################################

variable "enable_eks_oidc_provider" {
  type        = bool
  description = "Create EKS IAM OIDC provider used by IRSA roles"
  default     = true
}

##############################################
# Crossplane
##############################################

variable "enable_crossplane" {
  type        = bool
  description = "Install Crossplane via Helm in the EKS cluster"
  default     = true
}

variable "crossplane_namespace" {
  type        = string
  description = "Namespace for Crossplane Helm release"
  default     = "crossplane-system"
}

variable "crossplane_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Crossplane"
  default     = "2.2.0"
}

variable "crossplane_environment_config_api_version" {
  type        = string
  description = "API version used for Crossplane EnvironmentConfig"
  default     = "apiextensions.crossplane.io/v1beta1"
}

##############################################
# IRSA do Crossplane
##############################################

variable "enable_crossplane_irsa" {
  type        = bool
  description = "Create IRSA resources for Crossplane provider-aws"
  default     = true
  validation {
    condition     = !var.enable_crossplane_irsa || var.enable_eks_oidc_provider
    error_message = "enable_eks_oidc_provider must be true when enable_crossplane_irsa is true."
  }
}

variable "crossplane_irsa_namespace" {
  type        = string
  description = "Namespace of the Crossplane provider ServiceAccount used for IRSA"
  default     = "crossplane-system"
  validation {
    condition     = !var.enable_crossplane_irsa_serviceaccount_sync || var.crossplane_irsa_namespace == var.crossplane_namespace
    error_message = "crossplane_irsa_namespace must match crossplane_namespace when ServiceAccount sync is enabled."
  }
}

variable "crossplane_irsa_service_account" {
  type        = string
  description = "ServiceAccount name of the Crossplane provider used for IRSA"
  default     = "provider-aws"
}

variable "crossplane_irsa_role_name" {
  type        = string
  description = "IAM role name for Crossplane IRSA (empty uses <cluster_name>-crossplane-irsa-role)"
  default     = ""
}

variable "enable_crossplane_irsa_serviceaccount_sync" {
  type        = bool
  description = "Manage Crossplane ServiceAccount annotation with IRSA role ARN via Kubernetes provider"
  default     = true
  validation {
    condition     = !var.enable_crossplane_irsa_serviceaccount_sync || var.enable_crossplane
    error_message = "enable_crossplane must be true when enable_crossplane_irsa_serviceaccount_sync is true."
  }
}

##############################################
# External Secrets
##############################################

variable "enable_external_secrets" {
  type        = bool
  description = "Install external-secrets via Helm in the EKS cluster"
  default     = true
}

variable "external_secrets_namespace" {
  type        = string
  description = "Namespace for external-secrets Helm release"
  default     = "external-secrets"
}

variable "external_secrets_chart_version" {
  type        = string
  description = "Pinned Helm chart version for external-secrets"
  default     = "0.14.4"
}

variable "enable_external_secrets_irsa" {
  type        = bool
  description = "Create IRSA resources for external-secrets to read SSM Parameter Store"
  default     = true
  validation {
    condition     = !var.enable_external_secrets_irsa || var.enable_eks_oidc_provider
    error_message = "enable_eks_oidc_provider must be true when enable_external_secrets_irsa is true."
  }
}

variable "external_secrets_irsa_service_account" {
  type        = string
  description = "ServiceAccount name used by external-secrets controller for IRSA"
  default     = "external-secrets"
}

variable "external_secrets_irsa_role_name" {
  type        = string
  description = "IAM role name for external-secrets IRSA (empty uses <cluster_name>-external-secrets-irsa-role)"
  default     = ""
}

##############################################
# SSM Parameter Store (metadados do cluster)
##############################################

variable "enable_cluster_metadata_ssm" {
  type        = bool
  description = "Store cluster metadata in SSM Parameter Store for future IRSA automation"
  default     = true
}

variable "cluster_metadata_ssm_prefix" {
  type        = string
  description = "Base path prefix for cluster metadata parameters in SSM"
  default     = "/platform/bootstrap"
}
