terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.55.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 1.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 1.2"
    }
  }
}
provider "aws" {
  region  = "ap-south-1"
  profile = var.costcentre
}
