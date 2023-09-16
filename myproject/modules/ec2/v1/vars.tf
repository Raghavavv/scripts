variable "environment" {
  description = "The Envrionment name."
  type        = string
}
variable "region" {
  description = "The AWS region."
  type        = string
}

variable "ami_id" {
  description = "The project name."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID."
  type        = string
}

variable "vpc_cidr" {
  description = "The list of AWS subnets IDs for EC2 instance."
  type        = list(string)
}

variable "instance_type" {
  description = "The node instance type."
  type        = string
}
variable "azs" {
  description = "The availability Zones in the region."
  type        = list(string)
}

variable "server_name" {
  description = "The project name."
  type        = string
}

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
}

variable "keypair_to_download" {
  description = "If true, EC2 keypair will create "
  type        = bool
}

variable "number_of_instances" {
  description = "The Number of instance can launch "
  type        = number
}

variable "sg_cidr_blocks" {
  description = "The Cidr Blocks to allow Traffic"
  type        = list(string)
}
variable "costcentre" {
  description = "The costcentre Name."
  type        = string
}

