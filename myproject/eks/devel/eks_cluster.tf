module "eks" {
  source              = "../../modules/eks/v2/"
  environment         = var.environment
  eks_subnets         = var.eks_subnets
  instance_types      = var.instance_types
  disk_size           = var.disk_size
  eks_profile_fargate = var.eks_profile_fargate
  region              = var.region
  appname             = var.appname
  image_repo          = var.image_repo
  container_port      = var.container_port
  cluster_version     = var.cluster_version
  costcentre          = var.costcentre
}
