######################### Create Public Routing Table ######################

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name"        = "public-${var.environment}"
    "Environment" = var.environment
  }
}

######################## Create Routes for Public Routing Table ################

resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

##################### Assign Routes to the Public Routing Table ###############

resource "aws_route_table_association" "public-rta" {
  count          = 3
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-subnet.*.id[count.index]
}

##################### Create Private Routing Table ###########################

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name"        = "private-${var.environment}"
    "Environment" = var.environment
  }
}

######################### Create routes for Private Routing Table ############################

resource "aws_route" "private-rt" {
  count                  = 1
  route_table_id         = aws_route_table.private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw.id
}
########################## Assign routs to Private Route Tabel ###################

resource "aws_route_table_association" "private-rta" {
  count          = 3
  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-subnet.*.id[count.index]
}
