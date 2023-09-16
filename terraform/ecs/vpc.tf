# VPC
resource "aws_vpc" "bizom_vpc" {
  cidr_block = "${var.vpc_cidr[var.environment]}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "${var.cluster[var.environment]}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "bizom_igw" {
  vpc_id = "${aws_vpc.bizom_vpc.id}"
  tags = {
    "Name" = "main"
  }
}

# Subnets : public
resource "aws_subnet" "public" {
  count             = "${length(var.subnets_cidr[var.environment])}"
  vpc_id            = "${aws_vpc.bizom_vpc.id}"
  cidr_block        = "${element(var.subnets_cidr[var.environment],count.index)}"
  availability_zone = "${element(var.azs[var.aws_region],count.index)}"
  tags = {
    "Name" = "${var.environment}${count.index+1}/Public"
  }
}

# Route table: attach Internet Gateway 
resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.bizom_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.bizom_igw.id}"
  }
  tags = {
    "Name" = "publicRouteTable"
  }
}

# Route table association with public subnets
resource "aws_route_table_association" "a" {
  count          = "${length(var.subnets_cidr[var.environment])}"
  subnet_id      = "${element(aws_subnet.public.*.id,count.index)}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

# Output
output "vpc_arn" { value = "aws_vpc.bizom_vpc.arn" }
output "vpc_name" { value = "aws_vpc.bizom_vpc.tags.Name" }
