locals {
  eks_oidc_short = replace(local.oidc_issuer_url, "https://", "")
}

// ============================================================================
// EBS CSI DRIVER - Now as a managed add-on (breaking change from Helm chart)
// ============================================================================
resource "aws_iam_role" "ebs_csi" {
  name = "${data.aws_eks_cluster.cluster.name}-ebs-csi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "EksIrsa"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_arn.cluster.account}:oidc-provider/${local.eks_oidc_short}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.eks_oidc_short}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${local.eks_oidc_short}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = data.aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = data.aws_eks_cluster.cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi.version
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_addon.vpc_cni
  ]
}

// ============================================================================
// POD IDENTITY AGENT - New for EKS Pod Identity (IRSA successor)
// ============================================================================
data "aws_eks_addon_version" "pod_identity" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = data.aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name                = data.aws_eks_cluster.cluster.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = data.aws_eks_addon_version.pod_identity.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
}

// ============================================================================
// COREDNS
// ============================================================================
data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = data.aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = data.aws_eks_cluster.cluster.name
  addon_name                  = "coredns"
  addon_version               = data.aws_eks_addon_version.coredns.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_addon.vpc_cni
  ]
}

// ============================================================================
// KUBE-PROXY
// ============================================================================
data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = data.aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = data.aws_eks_cluster.cluster.name
  addon_name                  = "kube-proxy"
  addon_version               = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
}

// ============================================================================
// VPC CNI
// ============================================================================
resource "aws_iam_role" "vpc_cni" {
  name = "${data.aws_eks_cluster.cluster.name}-vpc-cni"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "EksIrsa"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_arn.cluster.account}:oidc-provider/${local.eks_oidc_short}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.eks_oidc_short}:sub" = "system:serviceaccount:kube-system:aws-node"
          "${local.eks_oidc_short}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = data.aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = data.aws_eks_cluster.cluster.name
  addon_name               = "vpc-cni"
  addon_version            = data.aws_eks_addon_version.vpc_cni.version
  service_account_role_arn = aws_iam_role.vpc_cni.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  configuration_values = jsonencode({
    enableNetworkPolicy = "true"
    env = {
      ENABLE_PREFIX_DELEGATION              = "true"
      ENABLE_POD_ENI                        = "true"
      POD_SECURITY_GROUP_ENFORCING_MODE     = "standard"
    }
  })
}

// ============================================================================
// SNAPSHOT CONTROLLER - For EBS snapshot support
// ============================================================================
data "aws_eks_addon_version" "snapshot_controller" {
  addon_name         = "snapshot-controller"
  kubernetes_version = data.aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "snapshot_controller" {
  cluster_name                = data.aws_eks_cluster.cluster.name
  addon_name                  = "snapshot-controller"
  addon_version               = data.aws_eks_addon_version.snapshot_controller.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}
