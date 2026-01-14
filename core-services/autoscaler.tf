
locals {
  cluster_autoscaler_values = {
    cloudProvider = "aws"
    rbac = {
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler.arn
        }
        name = "aws-cluster-autoscaler"
      }
    }
    autoDiscovery = {
      clusterName = data.aws_eks_cluster.cluster.name
    }
    awsRegion = data.aws_arn.cluster.region
    additionalLabels = var.md_metadata.default_tags
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name = substr("${var.md_metadata.name_prefix}-clusterautoscaler", 0, 64)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "EKSClusterAutoscaler"
      Effect = "Allow",
      Principal = {
        Federated = "arn:aws:iam::${data.aws_arn.cluster.account}:oidc-provider/${local.eks_oidc_short}"
      }
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${local.eks_oidc_short}:sub" = "system:serviceaccount:kube-system:aws-cluster-autoscaler"
          "${local.eks_oidc_short}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name = "cluster-autoscaler"
  role = aws_iam_role.cluster_autoscaler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "eks:DescribeNodeGroup"
        ],
        Resource = "*"
      },
      {
        Effect : "Allow",
        Action : [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements"
        ],
        Resource : "*",
        Condition : {
          StringEquals : {
            "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled" : "true",
            "autoscaling:ResourceTag/kubernetes.io/cluster/${data.aws_eks_cluster.cluster.name}" : "owned"
          }
        }
      }
    ]
  })
}

resource "helm_release" "cluster-autoscaler" {
  name             = "aws-cluster-autoscaler"
  chart            = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  version          = "9.29.4"
  namespace        = "kube-system"
  create_namespace = true
  force_update     = true

  values = [
    yamlencode(local.cluster_autoscaler_values)
  ]
}