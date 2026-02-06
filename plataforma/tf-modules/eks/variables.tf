variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "aws_region" {
  type        = string
  description = "AWS region for providers."
  default     = "us-east-1"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version."
  default     = "1.29"
}

variable "allowed_azs" {
  type        = list(string)
  description = "Allowed availability zones for control plane subnets."
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_id" {
  type        = string
  description = "VPC id for the cluster."
  default     = ""
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for the cluster and node groups."
  default     = []
}

variable "enable_karpenter" {
  type        = bool
  description = "Enable Karpenter IAM and SQS dependencies."
  default     = true
}

variable "enable_fargate_karpenter" {
  type        = bool
  description = "Create a Fargate profile for the karpenter namespace."
  default     = true
}

variable "karpenter_namespace" {
  type        = string
  description = "Namespace used to run the Karpenter controller on Fargate."
  default     = "karpenter"
}

variable "karpenter_service_account" {
  type        = string
  description = "Service account name for the Karpenter controller."
  default     = "karpenter"
}

variable "karpenter_controller_role_name" {
  type        = string
  description = "IAM role name for the Karpenter controller."
  default     = "karpenter-controller"
}

variable "karpenter_node_role_name" {
  type        = string
  description = "IAM role name for nodes launched by Karpenter."
  default     = "karpenter-node"
}

variable "aws_auth_roles" {
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  description = "Additional aws-auth mapRoles entries."
  default     = []
}


variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
