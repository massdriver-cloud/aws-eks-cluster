// Making this a hard-coded conditional for now, because once we support prometheus it will become conditional based on prometheus
// since it is effectively replaced by the prometheus-adapter https://github.com/kubernetes-sigs/prometheus-adapter
module "metrics-server" {
  count     = true ? 1 : 0
  source    = "github.com/massdriver-cloud/terraform-modules//k8s-metrics-server?ref=54da4ef"
  release   = "metrics-server"
  namespace = "md-observability"
}

// Making this a hard-coded conditional for now. Unless the user is running prometheus (or integrates an observability package like DD)
// there isn't much point to this service.
module "kube-state-metrics" {
  count       = true ? 1 : 0
  source      = "github.com/massdriver-cloud/terraform-modules//k8s-kube-state-metrics?ref=54da4ef"
  md_metadata = var.md_metadata
  release     = "kube-state-metrics"
  namespace   = "md-observability"
}

module "opensearch" {
  #   count              = var.observability.logging.destination == "opensearch" ? 1 : 0
  # Temporary workaround for having to comment out obervability param in massdriver.yaml
  count              = 0
  source             = "github.com/massdriver-cloud/terraform-modules//k8s-opensearch?ref=c32a6dc"
  md_metadata        = var.md_metadata
  release            = "opensearch"
  namespace          = "md-observability"
  kubernetes_cluster = local.kubernetes_cluster_artifact
  helm_additional_values = {
    persistence = {
      # Temporary workaround for having to comment out obervability param in massdriver.yaml
      #   size = var.observability.logging.opensearch.persistence_size
      size = "8Gi"
    }
  }
  enable_dashboards = true
  // this adds a retention policy to move indexes to warm after 1 day and delete them after a user configurable number of days
  ism_policies = {
    # Temporary workaround for having to comment out obervability param in massdriver.yaml
    # "hot-warm-delete" : templatefile("${path.module}/logging/opensearch/ism_hot_warm_delete.json.tftpl", { "log_retention_days" : var.observability.logging.opensearch.retention_days })
    "hot-warm-delete" : templatefile("${path.module}/logging/opensearch/ism_hot_warm_delete.json.tftpl", { "log_retention_days" : 7 })
  }
}
