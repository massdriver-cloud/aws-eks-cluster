locals {
  enable_ebs_csi = true
}

module "ebs_csi" {
  source = "github.com/massdriver-cloud/terraform-modules//k8s/aws-ebs-csi-driver?ref=b4c1dda"
  // Using a count here in case we ever want to back this out to a conditional
  count               = local.enable_ebs_csi ? 1 : 0
  kubernetes_version  = var.k8s_version
  eks_cluster_arn     = data.aws_eks_cluster.cluster.arn
  eks_oidc_issuer_url = local.oidc_issuer_url
}

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
