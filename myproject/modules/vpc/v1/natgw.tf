
################ Create NAT Gateway for Private subnets #######################
resource "aws_nat_gateway" "natgw" {
  allocation_id     = aws_eip.nat_eip.id
  subnet_id         = aws_subnet.public-subnet[0].id
  connectivity_type = "public"
  depends_on = [
    aws_internet_gateway.igw
  ]
  tags = {
    "Name"        = "${var.environment}"
    "Environment" = var.environment
  }
}

######################## Create and elastic IP #################################

resource "aws_eip" "nat_eip" {
  vpc = true
  depends_on = [
    aws_internet_gateway.igw
  ]
  tags = {
    "Name"        = "${var.environment}"
    "Environment" = var.environment
  }
}
