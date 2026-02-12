locals {
  effective_vpc_id = var.vpc_id != null ? var.vpc_id : data.aws_vpc.default[0].id
  effective_subnet_ids = (
    var.subnet_ids != null && length(var.subnet_ids) > 0
    ? var.subnet_ids
    : data.aws_subnets.allowed[0].ids
  )
}

data "aws_vpc" "default" {
  count   = var.vpc_id == null ? 1 : 0
  default = true
}

data "aws_subnets" "allowed" {
  count = var.subnet_ids == null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.effective_vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = var.allowed_azs
  }
}

module "eks" {
  source = "./modules/eks"

  vpc_id                = local.effective_vpc_id
  subnet_ids            = local.effective_subnet_ids
  cluster_security_group_ids = var.cluster_security_group_ids
  cluster_name          = var.cluster_name
  kubernetes_version    = var.kubernetes_version
  nodegroup_name        = var.nodegroup_name
  node_instance_types   = var.node_instance_types
  node_min_size         = var.node_min_size
  node_max_size         = var.node_max_size
  node_desired_size     = var.node_desired_size
  node_disk_size        = var.node_disk_size
  node_capacity_type    = var.node_capacity_type
  node_labels           = var.node_labels
  node_taints           = var.node_taints
  cluster_role_name     = var.cluster_role_name
  node_role_name        = var.node_role_name
  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access
  public_access_cidrs      = var.public_access_cidrs
  cluster_log_types        = var.cluster_log_types
  enable_encryption        = var.enable_encryption
  kms_key_arn              = var.kms_key_arn
  tags                     = var.tags
  update_max_unavailable   = var.update_max_unavailable
  update_max_unavailable_percentage = var.update_max_unavailable_percentage
  enable_addons            = var.enable_addons
  addon_versions           = var.addon_versions
  enable_cluster_creator_admin = var.enable_cluster_creator_admin
  cluster_creator_arn          = var.cluster_creator_arn
  access_entries               = var.access_entries
}
