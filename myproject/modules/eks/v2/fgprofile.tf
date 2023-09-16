resource "aws_eks_fargate_profile" "main_fargate" {
  count                  = var.eks_profile_fargate ? 1 : 0
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn
  subnet_ids             = var.eks_subnets

  selector { 
     namespace = "kube-system" 
  }

  selector { 
    namespace = "${var.environment}-services"
  }
}

resource "aws_iam_role" "eks-fargate-profile" {
  name                  = "eks-fargate-profile"
  force_detach_policies = true

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-fargate-profile" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-profile.name
}
