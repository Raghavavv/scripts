################# Create Internet Gateway for public Subnets ######################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name"        = "${var.environment}"
    "Environment" = var.environment
  }
}

