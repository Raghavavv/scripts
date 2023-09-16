resource "aws_eks_cluster" "main" {
  name     = "${var.environment}-cluster"
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster_role.arn
  # enabled_cluster_log_types = ["audit", "controllerManager", "scheduler", "Authenticator", "API server"]
  vpc_config {
    subnet_ids              = var.eks_subnets
    endpoint_private_access = false
    endpoint_public_access  = true
    ## subnet_ids = concat(var.public_subnets.*.id, var.private_subnets.*.id) ##
  }
  timeouts {
    delete = "30m"
  }

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster,
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.AmazonEKSCloudWatchMetricsPolicy,
    aws_iam_role_policy_attachment.AmazonEKSCluserNLBPolicy,
    aws_iam_role_policy_attachment.eks-fargate-profile

  ]
  tags = {
    "Name"        = "${var.environment}-cluster"
    "Environment" = var.environment
    "CostCentre"  = var.costcentre
  }
}

