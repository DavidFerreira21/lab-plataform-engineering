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
