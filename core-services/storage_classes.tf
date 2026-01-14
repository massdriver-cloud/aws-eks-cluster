// ============================================================================
// STORAGE CLASSES - Default gp3 storage class for EBS CSI driver
// ============================================================================

resource "kubernetes_storage_class_v1" "gp3_default" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}

// Optional: gp3 with higher IOPS for performance workloads
resource "kubernetes_storage_class_v1" "gp3_high_iops" {
  metadata {
    name = "gp3-high-iops"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    iops      = "16000"
    throughput = "1000"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}

// Optional: io2 for mission-critical workloads requiring guaranteed IOPS
resource "kubernetes_storage_class_v1" "io2" {
  metadata {
    name = "io2"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type      = "io2"
    iops      = "10000"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}
