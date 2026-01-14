
locals {
  log_group_name = "/aws/eks/${local.cluster_name}/cluster"
}

resource "aws_cloudwatch_log_group" "control_plane" {
  name              = local.log_group_name
  retention_in_days = try(var.monitoring.control_plane_log_retention, 7)
  kms_key_id        = module.kms.key_arn
}
