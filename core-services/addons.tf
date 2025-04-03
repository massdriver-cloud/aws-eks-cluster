locals {
  enable_ebs_csi = true
  eks_oidc_short = replace(local.oidc_issuer_url, "https://", "")
}

module "ebs_csi" {
  source = "github.com/massdriver-cloud/terraform-modules//k8s/aws-ebs-csi-driver?ref=42d293b"
  // Using a count here in case we ever want to back this out to a conditional
  count               = local.enable_ebs_csi ? 1 : 0
  kubernetes_version  = var.k8s_version
  eks_cluster_arn     = data.aws_eks_cluster.cluster.arn
  eks_oidc_issuer_url = local.oidc_issuer_url
}

// COREDNS
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
}

// KUBE-PROXY
data "aws_eks_addon_version" "kube-proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = data.aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = data.aws_eks_cluster.cluster.name
  addon_name                  = "kube-proxy"
  addon_version               = data.aws_eks_addon_version.kube-proxy.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
}

// VPC CNI
resource "aws_iam_role" "vpc-cni" {
  name = "${data.aws_eks_cluster.cluster.name}-vpc-cni"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      "Sid"    = "EksIrsa"
      "Effect" = "Allow",
      "Principal" = {
        "Federated" = "arn:aws:iam::${data.aws_arn.cluster.account}:oidc-provider/${local.eks_oidc_short}"
      }
      "Action" = "sts:AssumeRoleWithWebIdentity",
      "Condition" = {
        "StringEquals" = {
          "${local.eks_oidc_short}:sub" = "system:serviceaccount:kube-system:aws-node"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc-cni" {
  role       = aws_iam_role.vpc-cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_eks_addon_version" "vpc-cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = data.aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name                = data.aws_eks_cluster.cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = data.aws_eks_addon_version.vpc-cni.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  service_account_role_arn = aws_iam_role.vpc-cni.arn
}
