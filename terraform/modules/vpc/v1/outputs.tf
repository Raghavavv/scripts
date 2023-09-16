output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "The ID of the VPC."
}

output "public_subnets" {
  value       = aws_subnet.public-subnet.*.id
  description = "The ID of the Public subnets."
}

output "private_subnets" {
  value       = aws_subnet.private-subnet.*.id
  description = "The ID of the Private subnets."
}

