data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.main.id
}
resource "null_resource" "k8s_patcher" {
  depends_on = [aws_eks_fargate_profile.main_fargate]

  provisioner "local-exec" {
    command =  <<EOT
      aws eks --region "${var.region}" update-kubeconfig --name "${var.environment}-cluster"
      kubectl get ns
      kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
     EOT
     }
}

