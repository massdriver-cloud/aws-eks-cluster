resource "kubernetes_daemonset" "nvidia" {
  count = length([for ng in var.node_groups : ng if can(regex("^[p0-9]\\..*", ng.instance_type))]) > 0 ? 1 : 0
  metadata {
    name      = "nvidia-device-plugin-daemonset"
    namespace = kubernetes_namespace_v1.md-core-services.metadata.0.name
    labels = merge(var.md_metadata.default_tags, {
      k8s-app = "nvidia-device-plugin-daemonset"
    })
  }
  spec {
    selector {
      match_labels = {
        name = "nvidia-device-plugin-ds"
      }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        labels = merge(var.md_metadata.default_tags, {
          name = "nvidia-device-plugin-ds"
        })
        annotations = {
          "scheduler.alpha.kubernetes.io/critical-pod" : ""
        }
      }
      spec {
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "accelerator"
                  operator = "In"
                  values   = ["nvidia"]
                }
              }
            }
          }
        }
        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }
        toleration {
          key      = "nvidia.com/gpu"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        toleration {
          key      = "sku"
          operator = "Equal"
          value    = "gpu"
          effect   = "NoSchedule"
        }
        container {
          name  = "nvidia-device-plugin-ctr"
          image = "nvcr.io/nvidia/k8s-device-plugin:v0.9.0"
          args  = ["--fail-on-init-error=false"]
          security_context {
            privileged = false
            capabilities {
              drop = ["all"]
            }
          }
          volume_mount {
            name       = "device-plugin"
            mount_path = "/var/lib/kubelet/device-plugins"
          }
        }
        volume {
          name = "device-plugin"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }
      }
    }
  }
}
