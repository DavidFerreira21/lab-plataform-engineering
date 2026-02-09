resource "aws_iam_role" "cluster" {
  name               = var.cluster_role_name
  assume_role_policy = data.aws_iam_policy_document.cluster_trust.json
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_vpc" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role" "node" {
  name               = var.node_role_name
  assume_role_policy = data.aws_iam_policy_document.node_trust.json
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_kms_key" "eks" {
  count       = var.enable_encryption && (var.kms_key_arn == null || var.kms_key_arn == "") ? 1 : 0
  description = "EKS secrets encryption key"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowRoot"
        Effect   = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid      = "AllowEKS"
        Effect   = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
        Action   = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

locals {
  effective_kms_key_arn = (
    var.kms_key_arn != null && var.kms_key_arn != ""
    ? var.kms_key_arn
    : (length(aws_kms_key.eks) > 0 ? aws_kms_key.eks[0].arn : null)
  )
  subnet_vpc_match = alltrue([
    for s in data.aws_subnet.selected : s.vpc_id == var.vpc_id
  ])
  cluster_creator_arn = (
    var.cluster_creator_arn != null && var.cluster_creator_arn != ""
    ? var.cluster_creator_arn
    : data.aws_caller_identity.current.arn
  )
  access_entries = concat(
    var.enable_cluster_creator_admin ? [
      {
        principal_arn = local.cluster_creator_arn
        policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        scope_type    = "cluster"
        namespaces    = []
      }
    ] : [],
    var.access_entries
  )
  access_entry_map = {
    for idx, entry in local.access_entries :
    tostring(idx) => entry
  }
  addon_names = ["vpc-cni", "coredns", "kube-proxy"]
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = var.cluster_log_types

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
    security_group_ids      = var.cluster_security_group_ids
  }

  dynamic "encryption_config" {
    for_each = var.enable_encryption ? [1] : []
    content {
      resources = ["secrets"]
      provider {
        key_arn = local.effective_kms_key_arn
      }
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc
  ]

  lifecycle {
    precondition {
      condition     = length(var.subnet_ids) >= 2
      error_message = "Need at least 2 subnets in subnet_ids."
    }
    precondition {
      condition     = local.subnet_vpc_match
      error_message = "All subnet_ids must belong to vpc_id."
    }
    precondition {
      condition     = var.endpoint_public_access ? length(var.public_access_cidrs) > 0 : true
      error_message = "public_access_cidrs is required when endpoint_public_access is true."
    }
    precondition {
      condition     = var.enable_encryption ? (local.effective_kms_key_arn != null && local.effective_kms_key_arn != "") : true
      error_message = "KMS key ARN is required or must be created when enable_encryption is true."
    }
  }

  tags = var.tags
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.nodegroup_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.node_instance_types
  disk_size       = var.node_disk_size
  capacity_type   = var.node_capacity_type

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  labels = var.node_labels

  dynamic "taint" {
    for_each = var.node_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  update_config {
    max_unavailable = var.update_max_unavailable
    max_unavailable_percentage = var.update_max_unavailable_percentage
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
    aws_iam_role_policy_attachment.node_ssm
  ]

  tags = var.tags
}

resource "aws_eks_access_entry" "this" {
  for_each = local.access_entry_map

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  for_each = local.access_entry_map

  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = each.value.policy_arn
  principal_arn = each.value.principal_arn

  access_scope {
    type       = each.value.scope_type
    namespaces = each.value.namespaces
  }
}

resource "aws_eks_addon" "this" {
  for_each = var.enable_addons ? toset(local.addon_names) : []

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.value
  addon_version = lookup(var.addon_versions, each.value, null)

  depends_on = [aws_eks_cluster.this]
}
