locals {
  enable_ebs_csi        = true
  region                = var.vpc.specs.aws.region
  cluster_name          = var.md_metadata.name_prefix
  oidc_issuer_url_short = replace(local.oidc_issuer_url, "https://", "")
}

module "ebs_csi" {
  source = "github.com/massdriver-cloud/terraform-modules//k8s/aws-ebs-csi-driver?ref=b4c1dda"
  // Using a count here in case we ever want to back this out to a conditional
  count               = local.enable_ebs_csi ? 1 : 0
  kubernetes_version  = var.k8s_version
  eks_cluster_arn     = data.aws_eks_cluster.cluster.arn
  eks_oidc_issuer_url = local.oidc_issuer_url
}





data "http" "load_balancer_controller" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "load_balancer_controller" {
  name        = "${var.md_metadata.name_prefix}-load-balancer-controller"
  description = "IAM Policy for AWS Load Balancer Controller"
  policy      = data.http.load_balancer_controller.response_body
}

resource "aws_iam_role" "load_balancer_controller" {
  name = "${var.md_metadata.name_prefix}-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_arn.cluster.account}:oidc-provider/${local.oidc_issuer_url_short}"
      }
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        "StringEquals" = {
          "${local.oidc_issuer_url_short}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  policy_arn = aws_iam_policy.load_balancer_controller.arn
  role       = aws_iam_role.load_balancer_controller.name
}

resource "helm_release" "load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.11.0"

  values = [yamlencode({
    clusterName = local.cluster_name
    region      = local.region
    vpcId       = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id

    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.load_balancer_controller.arn
      }
    }
  })]
}
