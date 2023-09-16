variable "environment" { type = string }
variable "eks_subnets" { type = list(string) }
variable "instance_types" { type = list(string) }
variable "disk_size" { type = number }
variable "eks_profile_fargate" { type = bool }

