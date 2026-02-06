output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name."
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS API server endpoint."
}

output "cluster_ca_certificate" {
  value       = module.eks.cluster_certificate_authority_data
  description = "Base64-encoded CA data."
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Security group ID for the EKS control plane."
}

output "node_security_group_id" {
  value       = module.eks.node_security_group_id
  description = "Security group ID for the managed node group."
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN for IRSA."
}

output "karpenter_controller_role_arn" {
  value       = var.enable_karpenter ? aws_iam_role.karpenter_controller[0].arn : null
  description = "IAM role ARN for the Karpenter controller."
}

output "karpenter_node_role_arn" {
  value       = var.enable_karpenter ? aws_iam_role.karpenter_node[0].arn : null
  description = "IAM role ARN for nodes launched by Karpenter."
}

output "karpenter_instance_profile_name" {
  value       = var.enable_karpenter ? aws_iam_instance_profile.karpenter[0].name : null
  description = "Instance profile name for Karpenter nodes."
}

output "karpenter_interruption_queue_name" {
  value       = var.enable_karpenter ? aws_sqs_queue.karpenter_interruptions[0].name : null
  description = "SQS queue for Karpenter interruption handling."
}
