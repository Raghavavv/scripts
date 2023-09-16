module "ec2" {
  source                      = "../../modules/ec2/v2/"
  environment                 = var.environment
  region                      = var.region
  ami_id                      = var.ami_id
  vpc_id                      = var.vpc_id
  vpc_cidr                    = var.vpc_cidr
  instance_type               = var.instance_type
  azs                         = var.azs
  server_name                 = var.server_name
  monitoring                  = var.monitoring
  enable_dns_hostnames        = var.enable_dns_hostnames
  associate_public_ip_address = var.associate_public_ip_address
  ebs_optimized               = var.ebs_optimized
  keypair_to_download 	      = var.keypair_to_download
  number_of_instances         = var.number_of_instances
  sg_cidr_blocks	      = var.sg_cidr_blocks
}
