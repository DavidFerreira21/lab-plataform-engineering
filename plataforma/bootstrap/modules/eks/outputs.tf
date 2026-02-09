output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "EKS cluster endpoint"
}

output "cluster_ca" {
  value       = aws_eks_cluster.this.certificate_authority[0].data
  description = "EKS cluster CA data (base64)"
}

output "nodegroup_name" {
  value       = aws_eks_node_group.this.node_group_name
  description = "EKS node group name"
}

output "vpc_id" {
  value       = var.vpc_id
  description = "VPC ID used by EKS"
}

output "subnet_ids" {
  value       = var.subnet_ids
  description = "Subnet IDs used by EKS"
}

output "kms_key_arn" {
  value       = local.effective_kms_key_arn
  description = "KMS key ARN used for EKS secrets encryption"
}
