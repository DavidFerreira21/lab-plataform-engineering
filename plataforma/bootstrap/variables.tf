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
  description = "Allowed AZs for selecting subnets when subnet_ids is not set"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_id" {
  type        = string
  description = "Custom VPC ID. If null, use default VPC."
  default     = null
}

variable "subnet_ids" {
  type        = list(string)
  description = "Custom subnet IDs. If null, select by vpc_id + allowed_azs."
  default     = null
}

variable "cluster_security_group_ids" {
  type        = list(string)
  description = "Additional security group IDs for the EKS control plane"
  default     = null
}

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

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for EKS secrets encryption"
  default     = null
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
