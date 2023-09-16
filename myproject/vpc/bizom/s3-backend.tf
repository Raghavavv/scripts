terraform {
  backend "s3" {
    bucket = "bizom-terraform"
    key    = "vpc/bizom/terraform.tfstate"
    region = "ap-south-1"
  }
}
