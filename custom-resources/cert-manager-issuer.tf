locals {
  route53_hosted_zone_ids = [
    for hosted_zone_arn in var.core_services.route53_hosted_zones :
    element(split("/", hosted_zone_arn), 1)
  ]
  enable_cert_manager = length(local.route53_hosted_zone_ids) > 0
  route53_zone_to_domain_map = {
    for zone in local.route53_hosted_zone_ids :
    zone => data.aws_route53_zone.hosted_zones[zone].name
  }
}

data "aws_route53_zone" "hosted_zones" {
  for_each = toset(local.route53_hosted_zone_ids)
  zone_id  = each.key
}

data "aws_arn" "eks_cluster" {
  arn = data.aws_eks_cluster.cluster.arn
}

resource "kubernetes_manifest" "cluster_issuer" {
  count = local.enable_cert_manager ? 1 : 0
  manifest = {
    "apiVersion" = "cert-manager.io/v1",
    "kind"       = "ClusterIssuer",
    "metadata" = {
      "name" : "letsencrypt-prod"
    },
    "spec" = {
      "acme" = {
        // need to get this e-mail from the domain
        "email" : "support+letsencrypt@massdriver.cloud"
        "server" : "https://acme-v02.api.letsencrypt.org/directory"
        "privateKeySecretRef" = {
          "name" : "letsencrypt-prod-issuer-account-key"
        },
        "solvers" = concat([for zone, name in local.route53_zone_to_domain_map : {
          "selector" = {
            "dnsZones" = [
              name
            ]
          },
          "dns01" = {
            "route53" = {
              "region" : data.aws_arn.eks_cluster.region
              "hostedZoneID" : zone
            }
          }
          }], [ // could put other solvers here
        ])
      }
    }
  }
}
