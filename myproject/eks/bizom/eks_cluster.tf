module "eks" {
  source              = "../../modules/eks/v1/"
  environment         = var.environment
  eks_subnets         = var.eks_subnets
  instance_types      = var.instance_types
  disk_size           = var.disk_size
  eks_profile_fargate = var.eks_profile_fargate
}
