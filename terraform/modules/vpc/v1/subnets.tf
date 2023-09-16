################# create Public Subnets ####################################
resource "aws_subnet" "public-subnet" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = {
    "Name"        = "public-${var.environment}-${count.index}"
    "Environment" = var.environment
  }
}

################## Create Private Subnets ###################################
resource "aws_subnet" "private-subnet" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 47)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false
  tags = {
    "Name"        = "private-${var.environment}-${count.index}"
    "Environment" = var.environment
  }
}
