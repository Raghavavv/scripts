module "vpc" {
  source       = "../../modules/vpc/v1/"
  environment  = var.environment
  azs          = var.azs
  vpc_cidr     = var.vpc_cidr
  vpc_flowlogs = var.vpc_flowlogs
  costcentre  = var.costcentre
}
