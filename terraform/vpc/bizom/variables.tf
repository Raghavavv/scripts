variable "environment" { type = string }
variable "azs" { type = list(string) }
variable "vpc_cidr" { type = string }
variable "vpc_flowlogs" { type = bool }
variable "costcentre" { type = string }

