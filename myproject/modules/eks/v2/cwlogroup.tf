resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.environment}/cluster"
  retention_in_days = 7

  tags = {
    Name        = "${var.environment}-eks-cloudwatch-log-group"
    Environment = var.environment
  }
}
