locals {
  vpc_id             = element(split("/", var.vpc.data.infrastructure.arn), 1)
  public_subnet_ids  = [for subnet in var.vpc.data.infrastructure.public_subnets : element(split("/", subnet["arn"]), 1)]
  private_subnet_ids = [for subnet in var.vpc.data.infrastructure.private_subnets : element(split("/", subnet["arn"]), 1)]
  subnet_ids         = concat(local.public_subnet_ids, local.private_subnet_ids)

  cluster_name = var.md_metadata.name_prefix
}

resource "aws_eks_cluster" "cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.k8s_version

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  encryption_config {
    provider {
      key_arn = module.kms.key_arn
    }
        resources = ["secrets"]
  }

  vpc_config {
    subnet_ids              = local.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  kubernetes_network_config {
    service_ipv4_cidr = "172.20.0.0/16"
    ip_family         = "ipv4"
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_eks,
    aws_iam_role_policy_attachment.cluster_vpc,
    aws_iam_role_policy_attachment.cluster_encryption,
    aws_cloudwatch_log_group.control_plane
  ]
}

resource "aws_eks_node_group" "node_group" {
  for_each        = { for ng in var.node_groups : ng.name => ng }
  node_group_name = each.value.name
  cluster_name    = local.cluster_name
  version         = var.k8s_version
  subnet_ids      = local.private_subnet_ids
  node_role_arn   = aws_iam_role.node.arn
  instance_types  = [each.value.instance_type]
  ami_type        = "AL2023_x86_64_STANDARD"

  launch_template {
    id      = aws_launch_template.nodes[each.key].id
    version = "$Latest"
  }

  scaling_config {
    desired_size = each.value.min_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  dynamic "taint" {
    for_each = lookup(each.value, "advanced_configuration_enabled", false) ? [each.value.advanced_configuration.taint] : []
    content {
      key    = taint.value.taint_key
      value  = taint.value.taint_value
      effect = taint.value.effect
    }
  }

  lifecycle {
    create_before_destroy = true
    // desired_size issue: https://github.com/aws/containers-roadmap/issues/1637
    ignore_changes = [
      scaling_config.0.desired_size,
    ]
  }

  depends_on = [
    aws_eks_cluster.cluster
  ]
}

#checkov:skip=CKV_AWS_341:EKS requires hop limit of 2 for IRSA and cloud controller functionality
resource "aws_launch_template" "nodes" {
  for_each = { for ng in var.node_groups : ng.name => ng }
  name     = "${local.cluster_name}-${each.value.name}"

  update_default_version = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    // Hop limit must be 2 for pods to access IMDS for IRSA and cloud controller functionality
    // AL2023 + IMDSv2 requires hop limit of 2 for container networking to work properly
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  dynamic "tag_specifications" {
    // skipping "elastic-gpu" for now due to "Tagging an elastic gpu on create is not yet supported in this region" in some regions
    for_each = ["instance", "volume", "network-interface", "spot-instances-request"]
    content {
      resource_type = tag_specifications.value
      tags          = merge(var.md_metadata.default_tags, { "Name" : "${local.cluster_name}-${each.value.name}" })
    }
  }
}

# EKS Access Entry for Nodes - Required for API-based authentication mode
resource "aws_eks_access_entry" "nodes" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_iam_role.node.arn
  type          = "EC2_LINUX"

  depends_on = [
    aws_eks_cluster.cluster
  ]
}
