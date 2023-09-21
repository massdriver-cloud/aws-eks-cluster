data "aws_iam_policy_document" "assume_role" {
  count = var.fargate.enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["${element(split("cluster", aws_eks_cluster.cluster.arn), 0)}fargateprofile/${local.cluster_name}/*"]
    }
  }
}

resource "aws_iam_role" "fargate" {
  count = var.fargate.enabled ? 1 : 0

  name               = "${local.cluster_name}-fargate"
  assume_role_policy = one(data.aws_iam_policy_document.assume_role[*].json)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_fargate_pod_execution_role" {
  count = var.fargate.enabled ? 1 : 0

  policy_arn = "arn:${one(data.aws_partition.current[*].partition)}:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = one(aws_iam_role.fargate[*].name)
}

resource "aws_eks_fargate_profile" "main" {
  count = var.fargate.enabled ? 1 : 0

  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${local.cluster_name}-fargate"
  pod_execution_role_arn = one(aws_iam_role.fargate[*].arn)
  subnet_ids             = local.private_subnet_ids

  dynamic "selector" {
    for_each = toset(var.fargate.namespaces)
    content {
      namespace = selector.key
    }
  }
}
