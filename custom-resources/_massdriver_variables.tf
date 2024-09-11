// Auto-generated variable declarations from massdriver.yaml
variable "aws_authentication" {
  type = object({
    data = object({
      arn         = string
      external_id = optional(string)
    })
    specs = object({
      aws = optional(object({
        region = optional(string)
      }))
    })
  })
}
variable "core_services" {
  type = object({
    enable_efs_csi       = optional(bool)
    enable_ingress       = optional(bool)
    route53_hosted_zones = optional(list(string))
    storage_class_to_efs_map = optional(list(object({
      efs_arn            = string
      storage_class_name = string
    })))
  })
}
variable "fargate" {
  type = object({
    enabled    = optional(bool)
    namespaces = optional(list(string))
  })
  default = null
}
variable "k8s_version" {
  type = string
}
variable "md_metadata" {
  type = object({
    default_tags = object({
      managed-by  = string
      md-manifest = string
      md-package  = string
      md-project  = string
      md-target   = string
    })
    deployment = object({
      id = string
    })
    name_prefix = string
    observability = object({
      alarm_webhook_url = string
    })
    package = object({
      created_at             = string
      deployment_enqueued_at = string
      previous_status        = string
      updated_at             = string
    })
    target = object({
      contact_email = string
    })
  })
}
variable "monitoring" {
  type = object({
    control_plane_log_retention = number
    prometheus = object({
      grafana_enabled     = bool
      persistence_enabled = bool
      grafana_password    = optional(string)
    })
  })
}
variable "node_groups" {
  type = list(object({
    advanced_configuration_enabled = bool
    instance_type                  = string
    max_size                       = number
    min_size                       = number
    name_suffix                    = string
    advanced_configuration = optional(object({
      taint = optional(object({
        effect      = string
        taint_key   = string
        taint_value = string
      }))
    }))
  }))
}
variable "vpc" {
  type = object({
    data = object({
      infrastructure = object({
        arn  = string
        cidr = string
        internal_subnets = list(object({
          arn = string
        }))
        private_subnets = list(object({
          arn = string
        }))
        public_subnets = list(object({
          arn = string
        }))
      })
    })
    specs = optional(object({
      aws = optional(object({
        region = optional(string)
      }))
    }))
  })
}
