##############################################
# Data sources: rede (VPC/Subnets)
##############################################

# Valores efetivos para VPC e subnets usados no modulo EKS.
locals {
  effective_vpc_id     = var.use_default_vpc ? data.aws_vpc.default[0].id : var.vpc_id
  effective_subnet_ids = var.use_default_vpc ? data.aws_subnets.default_vpc[0].ids : var.subnet_ids
}

data "aws_vpc" "default" {
  count   = var.use_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default_vpc" {
  count = var.use_default_vpc ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }

  filter {
    name   = "availability-zone"
    values = var.allowed_azs
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

##############################################
# Data sources: AWS identidade (usado por SSM)
##############################################

data "aws_caller_identity" "current" {}
