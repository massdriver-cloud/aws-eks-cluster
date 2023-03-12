
resource "aws_cloudwatch_log_group" "control_plane" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 7
}
