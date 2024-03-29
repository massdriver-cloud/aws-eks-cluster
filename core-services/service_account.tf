resource "kubernetes_service_account_v1" "massdriver-cloud-provisioner" {
  metadata {
    name      = "massdriver-cloud-provisioner"
    namespace = kubernetes_namespace_v1.md-core-services.metadata.0.name
    labels    = var.md_metadata.default_tags
  }
  automount_service_account_token = false
}

resource "kubernetes_cluster_role_binding_v1" "massdriver-cloud-provisioner" {
  metadata {
    name   = "massdriver-cloud-provisioner"
    labels = var.md_metadata.default_tags
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.massdriver-cloud-provisioner.metadata.0.name
    namespace = kubernetes_service_account_v1.massdriver-cloud-provisioner.metadata.0.namespace
  }
}

resource "kubernetes_secret_v1" "massdriver-cloud-provisioner_token" {
  metadata {
    name      = "massdriver-cloud-provisioner-token"
    namespace = kubernetes_namespace_v1.md-core-services.metadata.0.name
    labels    = var.md_metadata.default_tags
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.massdriver-cloud-provisioner.metadata.0.name
    }
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}
