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
}

data "aws_route53_zone" "hosted_zones" {
  for_each = toset(local.route53_hosted_zone_ids)
  zone_id  = each.key
}


module "cluster-autoscaler" {
  source             = "github.com/massdriver-cloud/terraform-modules//k8s-cluster-autoscaler-aws?ref=54da4ef"
  kubernetes_cluster = local.kubernetes_cluster_artifact
  md_metadata        = var.md_metadata
  release            = "aws-cluster-autoscaler"
  namespace          = "kube-system"
}

module "ingress_nginx" {
  source             = "github.com/massdriver-cloud/terraform-modules//k8s-ingress-nginx?ref=54da4ef"
  count              = var.core_services.enable_ingress ? 1 : 0
  kubernetes_cluster = local.kubernetes_cluster_artifact
  md_metadata        = var.md_metadata
  release            = "ingress-nginx"
  namespace          = local.core_services_namespace
  helm_additional_values = {
    controller = {
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
}

module "external_dns" {
  count                = local.enable_external_dns ? 1 : 0
  source               = "github.com/massdriver-cloud/terraform-modules//k8s-external-dns-aws?ref=c336d59"
  kubernetes_cluster   = local.kubernetes_cluster_artifact
  md_metadata          = var.md_metadata
  release              = "external-dns"
  namespace            = local.core_services_namespace
  route53_hosted_zones = local.route53_zone_to_domain_map
}

module "cert_manager" {
  source               = "github.com/massdriver-cloud/terraform-modules//k8s-cert-manager-aws?ref=54da4ef"
  count                = local.enable_cert_manager ? 1 : 0
  kubernetes_cluster   = local.kubernetes_cluster_artifact
  md_metadata          = var.md_metadata
  release              = "cert-manager"
  namespace            = local.core_services_namespace
  route53_hosted_zones = local.route53_zone_to_domain_map
}
