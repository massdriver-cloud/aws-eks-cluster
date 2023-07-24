module "alarm_channel" {
  count       = true ? 1 : 0
  source      = "github.com/massdriver-cloud/terraform-modules//k8s/alarm-channel?ref=2ba8cd9b49c081c78f659f8c19b9026d73468abf"
  md_metadata = var.md_metadata
  namespace   = kubernetes_namespace_v1.md-observability.metadata.0.name
  release     = var.md_metadata.name_prefix
}

module "pod_not_ready_alarm" {
  count                 = true ? 1 : 0
  source                = "github.com/massdriver-cloud/terraform-modules//k8s/prometheus_alarm?ref=2ba8cd9b49c081c78f659f8c19b9026d73468abf"
  md_metadata           = var.md_metadata
  display_name          = "Pods Ready"
  prometheus_alert_name = "KubePodNotReady"
}

module "pod_crash_looping_alarm" {
  count                 = true ? 1 : 0
  source                = "github.com/massdriver-cloud/terraform-modules//k8s/prometheus_alarm?ref=2ba8cd9b49c081c78f659f8c19b9026d73468abf"
  md_metadata           = var.md_metadata
  display_name          = "Pods Crash Looping"
  prometheus_alert_name = "KubePodCrashLooping"
}

module "deployment_replicas_mismatch_alarm" {
  count                 = true ? 1 : 0
  source                = "github.com/massdriver-cloud/terraform-modules//k8s/prometheus_alarm?ref=2ba8cd9b49c081c78f659f8c19b9026d73468abf"
  md_metadata           = var.md_metadata
  display_name          = "Deployment Replicas Accurate"
  prometheus_alert_name = "KubeDeploymentReplicasMismatch"
}

module "job_failed_alarm" {
  count                 = true ? 1 : 0
  source                = "github.com/massdriver-cloud/terraform-modules//k8s/prometheus_alarm?ref=2ba8cd9b49c081c78f659f8c19b9026d73468abf"
  md_metadata           = var.md_metadata
  display_name          = "Jobs Succeeded"
  prometheus_alert_name = "KubeJobFailed"
}
