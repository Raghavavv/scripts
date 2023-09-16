resource "aws_security_group" "control_traffic" {
  name        = "${var.environment}-${var.server_name}-SG"
  description = "Allow TLS inbound traffic"

  ingress {
    # SSH Port 22 allowed from any IP
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.sg_cidr_blocks
#    ipv6_cidr_blocks = ["::/0"]
  }
 ingress {
    # SSH Port 22 allowed from any IP
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.vpc_cidr
#    ipv6_cidr_blocks = ["::/0"]
  }

 ingress {
    # 2049 allowed at inbount
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = var.vpc_cidr
#    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.vpc_cidr
#    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
#    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.environment}-${var.server_name}-allow_tls"
  }
}
