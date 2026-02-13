##############################################
# Configuracao principal do cluster
##############################################

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID used by EKS"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs used by EKS"
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
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types for the node group"
}

variable "node_min_size" {
  type        = number
  description = "Node group min size"
}

variable "node_max_size" {
  type        = number
  description = "Node group max size"
}

variable "node_desired_size" {
  type        = number
  description = "Node group desired size"
}

variable "node_disk_size" {
  type        = number
  description = "Node group disk size (GiB)"
}

variable "node_capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT"
}

variable "node_labels" {
  type        = map(string)
  description = "Labels for nodes"
}

variable "node_taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  description = "Taints for nodes"
}

variable "cluster_role_name" {
  type        = string
  description = "IAM role name for EKS control plane"
}

variable "node_role_name" {
  type        = string
  description = "IAM role name for EKS nodes"
}

##############################################
# Endpoint e observabilidade
##############################################

variable "endpoint_public_access" {
  type        = bool
  description = "Expose EKS public endpoint"
}

variable "endpoint_private_access" {
  type        = bool
  description = "Expose EKS private endpoint"
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

##############################################
# Criptografia e tags
##############################################

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


##############################################
# Atualizacao de node group e addons
##############################################

variable "update_max_unavailable" {
  type        = number
  description = "Max unavailable nodes during node group update"
  default     = 1
}

variable "update_max_unavailable_percentage" {
  type        = number
  description = "Max unavailable percentage during node group update"
  default     = null
  validation {
    condition     = var.update_max_unavailable == null || var.update_max_unavailable_percentage == null
    error_message = "Set only one of update_max_unavailable or update_max_unavailable_percentage."
  }
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

##############################################
# Acesso ao cluster via EKS Access API
##############################################

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
# OIDC provider para IRSA
##############################################

variable "enable_oidc_provider" {
  type        = bool
  description = "Create IAM OIDC provider for EKS IRSA"
  default     = true
}
