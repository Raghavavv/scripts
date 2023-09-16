variable "environment" {
  description = "The Environment name that we are creating."
  type        = string
}

variable "costcentre" {
  description = "the costcentre who is applying the changes."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR for the VPC"
  type        = string
}

variable "azs" {
  description = "The list of AWS availability zones in the region."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "vpc_flowlogs" {
  description = "Either enable or disable VPC flowlogs."
  type        = bool
  default     = false
}
