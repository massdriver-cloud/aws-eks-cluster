locals {
  route53_hosted_zone_ids = [
    for hosted_zone_arn in var.core_services.route53_hosted_zones :
    element(split("/", hosted_zone_arn), 1)
  ]
  enable_cert_manager = length(local.route53_hosted_zone_ids) > 0
  enable_external_dns = length(local.route53_hosted_zone_ids) > 0
  route53_zone_to_domain_map = {
    for zone in local.route53_hosted_zone_ids :
    zone => data.aws_route53_zone.hosted_zones[zone].name
  }
  core_services_namespace = "md-core-services"

  storage_class_to_efs_arn_map = try({ for elem in var.core_services.storage_class_to_efs_map : elem.storage_class_name => elem.efs_arn }, {})
}

data "aws_route53_zone" "hosted_zones" {
  for_each = toset(local.route53_hosted_zone_ids)
  zone_id  = each.key
}

resource "kubernetes_namespace_v1" "md-core-services" {
  metadata {
    labels = var.md_metadata.default_tags
    name   = "md-core-services"
  }
}

module "cluster-autoscaler" {
  source             = "github.com/massdriver-cloud/terraform-modules//k8s-cluster-autoscaler-aws?ref=b4c1dda"
  kubernetes_cluster = local.kubernetes_cluster_artifact
  md_metadata        = var.md_metadata
  release            = "aws-cluster-autoscaler"
  namespace          = "kube-system"
  helm_additional_values = {
    serviceMonitor = {
      enabled   = true
      namespace = "kube-system"
      selector  = var.md_metadata.default_tags
    }
  }

  depends_on = [module.prometheus-observability]
}

module "ingress_nginx" {
  source             = "github.com/massdriver-cloud/terraform-modules//k8s-ingress-nginx?ref=b4c1dda"
  count              = var.core_services.enable_ingress ? 1 : 0
  kubernetes_cluster = local.kubernetes_cluster_artifact
  md_metadata        = var.md_metadata
  release            = "ingress-nginx"
  namespace          = kubernetes_namespace_v1.md-core-services.metadata.0.name
  helm_additional_values = {
    controller = {
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
      service = {
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"                  = "tcp"
          "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
          "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
        }
        externalTrafficPolicy = "Local"
      }
    }
  }

  depends_on = [module.prometheus-observability]
}

module "external_dns" {
  count                = local.enable_external_dns ? 1 : 0
  source               = "github.com/massdriver-cloud/terraform-modules//k8s-external-dns-aws?ref=b4c1dda"
  kubernetes_cluster   = local.kubernetes_cluster_artifact
  md_metadata          = var.md_metadata
  release              = "external-dns"
  namespace            = kubernetes_namespace_v1.md-core-services.metadata.0.name
  route53_hosted_zones = local.route53_zone_to_domain_map
  helm_additional_values = {
    txtPrefix = var.core_services.route53_hosted_zones_txt_prefix
    txtSuffix = var.core_services.route53_hosted_zones_txt_suffix
  }

  depends_on = [module.prometheus-observability]
}

module "cert_manager" {
  source               = "github.com/massdriver-cloud/terraform-modules//k8s-cert-manager-aws?ref=b4c1dda"
  count                = local.enable_cert_manager ? 1 : 0
  kubernetes_cluster   = local.kubernetes_cluster_artifact
  md_metadata          = var.md_metadata
  release              = "cert-manager"
  namespace            = kubernetes_namespace_v1.md-core-services.metadata.0.name
  route53_hosted_zones = local.route53_zone_to_domain_map

  depends_on = [module.prometheus-observability]
}

module "efs_csi" {
  source                       = "github.com/massdriver-cloud/terraform-modules//k8s/k8s-aws-efs-csi-driver?ref=b4c1dda"
  count                        = var.core_services.enable_efs_csi ? 1 : 0
  name_prefix                  = var.md_metadata.name_prefix
  eks_cluster_arn              = data.aws_eks_cluster.cluster.arn
  eks_oidc_issuer_url          = local.oidc_issuer_url
  release                      = "efs-csi"
  namespace                    = kubernetes_namespace_v1.md-core-services.metadata.0.name
  storage_class_to_efs_arn_map = local.storage_class_to_efs_arn_map

  depends_on = [module.prometheus-observability]
}
