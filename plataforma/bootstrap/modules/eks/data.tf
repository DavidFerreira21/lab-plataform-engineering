##############################################
# Data sources: trust policies IAM
##############################################

data "aws_iam_policy_document" "cluster_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "node_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

##############################################
# Data sources: conta AWS e subnets do cluster
##############################################

data "aws_caller_identity" "current" {}

data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

##############################################
# Data source: certificado OIDC do cluster
##############################################

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
