variable "cluster_version" {
  description = "The version of the cluster."
  type        = number
}

variable "environment" {
  description = "Write description for the variable."
  type        = string
}
variable "costcentre" {
  description = "Owner of the apply committed."
  type        = string
  default     = ""
}

variable "eks_subnets" {
  description = "The list of AWS subnets IDs for EKS cluster."
  type        = list(string)
}
variable "instance_types" {
  description = "The node instance type."
  type        = list(string)
}

variable "disk_size" {
  description = "The size of the root volume."
  type        = number
}

variable "eks_profile_fargate" {
  description = "Whether to enable the fargate profile or not"
  type        = bool
}

variable "region" {
  description = "The AWS region."
  type        = string
}

variable "appname" {
  description = "The APP/Service Name."
  type        = string
}

variable "image_repo" {
  description = "The ECR Repo URI"
  type        = string
}


variable "container_port" {
  description = "The Container Port"
  type        = number
}

