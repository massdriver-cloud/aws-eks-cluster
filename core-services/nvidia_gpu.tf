locals {
  gpu_regex = "^(p[0-9][a-z]*|g[0-9+][a-z]*|trn[0-9][a-z]*|inf[0-9]|dl[0-9][a-z]*|f[0-9]|vt[0-9])\\..*"
  has_gpu   = length(coalesce([for ng in var.node_groups : length(regexall(local.gpu_regex, ng.instance_type)) > 1 ? "gpu" : ""])) > 0
  is_gpu    = [for ng in var.node_groups : ng.instance_type if length(regexall(local.gpu_regex, ng.instance_type)) > 0]
}

resource "kubernetes_daemonset" "nvidia" {
  count = local.has_gpu ? 1 : 0
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
        priority_class_name = "system-node-critical"
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "node.kubernetes.io/instance-type"
                  operator = "In"
                  values   = local.is_gpu
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
          image = "nvcr.io/nvidia/k8s-device-plugin:v0.15.0"
          env {
            name  = "FAIL_ON_INIT_ERROR"
            value = "false"
          }
          security_context {
            privileged = true
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
