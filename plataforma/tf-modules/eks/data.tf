data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id_effective]
  }
}

locals {
  vpc_id_effective     = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id
  subnet_ids_effective = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.default.ids
}

locals {
  oidc_provider_host = module.eks.oidc_provider
  aws_auth_roles_effective = var.enable_karpenter ? concat(
    var.aws_auth_roles,
    [
      {
        rolearn  = aws_iam_role.karpenter_node[0].arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ]
  ) : var.aws_auth_roles
}
