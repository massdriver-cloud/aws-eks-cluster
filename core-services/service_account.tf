module "service_account" {
  source      = "github.com/massdriver-cloud/terraform-modules//k8s/service-account?ref=68ea334"
  name = var.md_metadata.name_prefix
  namespace = var.namespace
  labels = var.md_metadata.default_tags
}
