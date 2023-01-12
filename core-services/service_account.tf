module "core_services_service_account" {
  # source      = "github.com/massdriver-cloud/terraform-modules//k8s/service-account?ref=68ea334"
  source = "../../terraform-modules/k8s/service-account"
  name = var.md_metadata.name_prefix
  namespace = local.core_services_namespace
  labels = var.md_metadata.default_tags
}

# moved {
#   from = kubernetes_namespace_v1.md-core-services
#   to   = module.core_services_service_account.namespace
# }

moved {
  from = kubernetes_service_account.massdriver-cloud-provisioner
  to = module.core_services.service_account.id
}

# moved {
#   from = data.kubernetes_secret.massdriver-cloud-provisioner_service-account_secret
#   to  = module.service_account.secret
# }


# /Users/wbeebe/repos/massdriver-cloud/terraform-modules/k8s/service-account
