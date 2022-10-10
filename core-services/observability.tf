locals {
  enable_opensearch = var.observability.logging.destination == "opensearch"
  enable_fluentbit  = local.enable_opensearch
  observability_namespace = "md-observability"
}
// Making this a hard-coded conditional for now, because once we support prometheus it will become conditional based on prometheus
// since it is effectively replaced by the prometheus-adapter https://github.com/kubernetes-sigs/prometheus-adapter
module "metrics-server" {
  count     = true ? 1 : 0
  source    = "github.com/massdriver-cloud/terraform-modules//k8s-metrics-server?ref=54da4ef"
  release   = "metrics-server"
  namespace = local.observability_namespace
}

# // Making this a hard-coded conditional for now. Unless the user is running prometheus (or integrates an observability package like DD)
# // there isn't much point to this service.
# module "kube-state-metrics" {
#   count       = true ? 1 : 0
#   source      = "github.com/massdriver-cloud/terraform-modules//k8s-kube-state-metrics?ref=54da4ef"
#   md_metadata = var.md_metadata
#   release     = "kube-state-metrics"
#   namespace   = local.observability_namespace
# }

module "opensearch" {
  count              = local.enable_opensearch ? 1 : 0
  source             = "github.com/massdriver-cloud/terraform-modules//k8s-opensearch?ref=5fc9525"
  md_metadata        = var.md_metadata
  release            = "opensearch"
  namespace          = local.observability_namespace
  kubernetes_cluster = local.kubernetes_cluster_artifact
  helm_additional_values = {
    persistence = {
      size = "${var.observability.logging.opensearch.persistence_size}Gi"
    }
  }
  enable_dashboards = true
  // this adds a retention policy to move indexes to warm after 1 day and delete them after a user configurable number of days
  ism_policies = {
    "hot-warm-delete" : templatefile("${path.module}/logging/opensearch/ism_hot_warm_delete.json.tftpl", { "log_retention_days" : var.observability.logging.opensearch.retention_days })
  }
}

module "fluentbit" {
  count              = local.enable_fluentbit ? 1 : 0
  source             = "github.com/massdriver-cloud/terraform-modules//k8s-fluentbit?ref=f920d78"
  md_metadata        = var.md_metadata
  release            = "fluentbit"
  namespace          = local.observability_namespace
  kubernetes_cluster = local.kubernetes_cluster_artifact
  helm_additional_values = {
    config = {
      filters = file("${path.module}/logging/fluentbit/filter.conf")
      outputs = templatefile("${path.module}/logging/fluentbit/opensearch_output.conf.tftpl", {
        namespace = local.observability_namespace
      })
    }
  }
}

locals {
  enable_prometheus = var.observability.metrics.destination == "prometheus"
  prometheus_values = {
    alertmanager = {
      config = {
        receivers = [{
          name = "massdriver-cloud"
          webhook_configs = [{
            url = var.md_metadata.observability.alarm_webhook_url
            send_resolved = true
            max_alerts = 1
          }]
        }]
      }
    }
    prometheus = {
      prometheusSpec = {
        replicas = 2
        resources = {
          requests = {
            memory = "400Mi"
          }
        }
        retention = "${var.observability.metrics.prometheus.retention_days}d"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "gp2"
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.observability.metrics.prometheus.persistence_size
                }
              }
            }
          }
        }
      }
    }
  }
}

module "prometheus" {
  count = local.enable_prometheus ? 1 : 0
  source = "github.com/massdriver-cloud/terraform-modules//k8s/k8s-kube-prometheus-stack?ref=ec00875"
  release = "kube-prometheus-stack"
  namespace = local.observability_namespace
  helm_additional_values = local.prometheus_values
}