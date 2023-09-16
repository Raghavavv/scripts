data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.main.id
}

resource "null_resource" "k8s_patcher" {
  depends_on = [aws_eks_fargate_profile.main_fargate]

  triggers = {
    endpoint = aws_eks_cluster.main.endpoint
    ca_crt   = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token    = data.aws_eks_cluster_auth.eks.token
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}

