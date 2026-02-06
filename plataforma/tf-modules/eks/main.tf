module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = local.vpc_id_effective
  subnet_ids = local.subnet_ids_effective

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  fargate_profiles = var.enable_fargate_karpenter ? {
    karpenter = {
      name       = "karpenter"
      subnet_ids = var.subnet_ids
      selectors = [
        {
          namespace = var.karpenter_namespace
        }
      ]
    }
  } : {}

  tags = var.tags
}

resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(local.aws_auth_roles_effective)
  }

  depends_on = [module.eks]
}

data "aws_iam_policy_document" "karpenter_assume_role" {
  count = var.enable_karpenter ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:sub"
      values   = ["system:serviceaccount:${var.karpenter_namespace}:${var.karpenter_service_account}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_sqs_queue" "karpenter_interruptions" {
  count = var.enable_karpenter ? 1 : 0

  name                      = "${var.cluster_name}-karpenter-interruptions"
  message_retention_seconds = 300
  tags                      = var.tags
}

data "aws_iam_policy_document" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstances",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "iam:PassRole",
      "pricing:GetProducts",
      "ssm:GetParameter",
      "eks:DescribeCluster"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage"
    ]
    resources = [aws_sqs_queue.karpenter_interruptions[0].arn]
  }
}

resource "aws_iam_role" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0

  name               = var.karpenter_controller_role_name
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_policy" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0

  name   = "${var.cluster_name}-karpenter-controller"
  policy = data.aws_iam_policy_document.karpenter_controller[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0

  role       = aws_iam_role.karpenter_controller[0].name
  policy_arn = aws_iam_policy.karpenter_controller[0].arn
}

data "aws_iam_policy_document" "karpenter_node_assume_role" {
  count = var.enable_karpenter ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_node" {
  count = var.enable_karpenter ? 1 : 0

  name               = var.karpenter_node_role_name
  assume_role_policy = data.aws_iam_policy_document.karpenter_node_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
  count = var.enable_karpenter ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  count = var.enable_karpenter ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
  count = var.enable_karpenter ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  count = var.enable_karpenter ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name = "${var.cluster_name}-karpenter"
  role = aws_iam_role.karpenter_node[0].name
  tags = var.tags
}
