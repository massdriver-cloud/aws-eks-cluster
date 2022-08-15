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
  count       = true ? 1 : 0
  #TODO replace ref with a SHA once k8s-opensearch is merged
  source      = "github.com/massdriver-cloud/terraform-modules//k8s-opensearch?ref=opensearch"
  md_metadata = var.md_metadata
  release     = "opensearch"
  namespace   = "md-observability" # TODO should this be monitoring?
  helm_additional_values = {
    persistence = {
        size = var.opensearch_persistence_size
    }
    // TODO configure an index state management policy to delete old things https://opensearch.org/docs/latest/im-plugin/ism/index/
    // these can be configured with a pre-start lifecycle hook https://github.com/opensearch-project/helm-charts/blob/main/charts/opensearch/values.yaml#L373-L391
  } 
}
