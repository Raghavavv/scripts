terraform {
  backend "s3" {
    bucket = "bizom-terraform"
    key    = "ec2/bizom/terraform.tfstate"
    region = var.region
  }
}

