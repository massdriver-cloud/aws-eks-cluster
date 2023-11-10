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
  source      = "github.com/massdriver-cloud/terraform-modules//k8s-metrics-server?ref=b4c1dda"
  md_metadata = var.md_metadata
  release     = "metrics-server"
  namespace   = kubernetes_namespace_v1.md-observability.metadata.0.name

  depends_on = [module.prometheus-observability]
}

module "prometheus-observability" {
  count       = true ? 1 : 0
  source      = "github.com/massdriver-cloud/terraform-modules//massdriver/k8s-prometheus-observability?ref=b4c1dda"
  md_metadata = var.md_metadata
  release     = "massdriver"
  namespace   = kubernetes_namespace_v1.md-observability.metadata.0.name
  helm_additional_values = {
    prometheus = {
      prometheusSpec = {
        storageSpec = lookup(var.monitoring.prometheus, "persistence_enabled", false) ? {} : null
      }
    }
    prometheus-node-exporter = {
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [{
              matchExpressions = [{
                key      = "eks.amazonaws.com/compute-type"
                operator = "NotIn"
                values   = ["fargate"]
              }]
            }]
          }
        }
      }
    }
    grafana = {
      enabled       = lookup(var.monitoring.prometheus, "grafana_enabled", false)
      adminPassword = lookup(var.monitoring.prometheus, "grafana_password", "prom-operator")
    }
  }

  // prometheus requires persistent storage, which is managed by the EBS addon. This is more important on destruction since
  // volumes won't unbind properly if the EBS CSI driver is uninstalled before the volume, blocking destruction indefinitely.
  depends_on = [module.ebs_csi]
}

module "prometheus-rules" {
  count       = true ? 1 : 0
  source      = "github.com/massdriver-cloud/terraform-modules//massdriver/k8s-prometheus-rules?ref=b4c1dda"
  md_metadata = var.md_metadata
  release     = "massdriver"
  namespace   = kubernetes_namespace_v1.md-observability.metadata.0.name
  helm_additional_values = {
    defaultRules = {
      rules = {
        clusterAutoscaler = true
      }
    }
  }

  depends_on = [module.prometheus-observability]
}
