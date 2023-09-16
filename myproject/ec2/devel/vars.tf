variable "environment" { type = string }
variable "region" { type = string }
variable "ami_id" { type = string }
variable "vpc_cidr" { type = list(string) }
variable "vpc_id" { type = string }
variable "instance_type" { type = string }
variable "azs" { type = list(string) }
variable "server_name" { type = string }
variable "monitoring" { type = bool }
variable "enable_dns_hostnames" { type = bool }
variable "associate_public_ip_address" { type = bool }
variable "ebs_optimized" { type = bool }
variable "keypair_to_download" { type = bool }
variable "number_of_instances" { type = number }
variable "sg_cidr_blocks" { type = list(string) }
variable "costcentre" { type = string }



