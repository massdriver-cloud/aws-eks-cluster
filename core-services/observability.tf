resource "kubernetes_namespace_v1" "md-observability" {
  metadata {
    labels = var.md_metadata.default_tags
    name   = "md-observability"
  }
}

// Making this a hard-coded conditional for now, because once we support prometheus it will become conditional based on prometheus
// since it is effectively replaced by the prometheus-adapter https://github.com/kubernetes-sigs/prometheus-adapter
module "metrics-server" {
  count       = true ? 1 : 0
  source      = "github.com/massdriver-cloud/terraform-modules//k8s-metrics-server?ref=5529f6032f94464ae61592ee98e0e2348c6b2923"
  md_metadata = var.md_metadata
  release     = "metrics-server"
  namespace   = kubernetes_namespace_v1.md-observability.metadata.0.name
}

module "prometheus-observability" {
  count       = true ? 1 : 0
  source      = "github.com/massdriver-cloud/terraform-modules//massdriver/k8s-prometheus-observability?ref=e05f16a23f596d46b44fb1def0940562fd059f4d"
  md_metadata = var.md_metadata
  release     = "massdriver"
  namespace   = kubernetes_namespace_v1.md-observability.metadata.0.name
}

module "prometheus-rules" {
  count       = true ? 1 : 0
  source      = "github.com/massdriver-cloud/terraform-modules//massdriver/k8s-prometheus-rules?ref=e05f16a23f596d46b44fb1def0940562fd059f4d"
  md_metadata = var.md_metadata
  release     = "massdriver"
  namespace   = kubernetes_namespace_v1.md-observability.metadata.0.name

  depends_on = [module.prometheus-observability]
}
