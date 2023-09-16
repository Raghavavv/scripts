resource "aws_key_pair" "tf-key-pair" {
  count    = var.keypair_to_download ? 1 : 0
  key_name   = "${var.server_name}-keypair"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
/*
  module "key_pair" {
    source = "terraform-aws-modules/key-pair/aws"

    key_name   = "${var.environment}-ec2-keypair"
    public_key = trimspace(tls_private_key.rsa.public_key_openssh)
}
*/
resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "/home/raghavav/Downloads/${var.server_name}-keypair.pem"
}


