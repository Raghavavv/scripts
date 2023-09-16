variable "aws_region" {
#  default = "us-east-2"
  default = "ap-south-1"
}

#. Change this variable to create the desired environment.
variable "environment" {
#  default = "devel"
  default = "staging"
}

variable "git_source_branch" {
#  default = "origin/development"
  default = "origin/release/20200213"
}

variable "git_target_branch" {
#  default = "terraform"
}

variable "git_config_user" {
#  default = "rajput007"
}

variable "git_config_email" {
#  default = "gaurav.rajput@mobisy.com"
}

variable "cluster" {
  type    = "map"
  default = {
    "devel"   = "ecs-devel-cluster"
    "staging" = "ecs-staging-cluster"
    "prod"    = "ecs-prod-cluster"
  }
}

variable "vpc_cidr" {
  type        = "map"
  description = "CIDR block for the VPC."
  default = {
    devel   = "10.37.0.0/16"
    staging = "10.117.0.0/16"
    prod    = "10.127.0.0/16"
  }
}

variable "vpc_redis_cidr" {
  type        = "map"
  description = "CIDR block for the VPC."
  default = {
    devel   = "10.37.37.0/24"
    staging = "10.117.117.0/24"
    prod    = "10.127.127.0/24"
  }
}

variable "ecs_role_arn" {
  default = "arn:aws:iam::596849958460:role/ecsTaskExecutionRole"
}

variable "subnets_cidr" {
  type        = "map"
  description = "CIDR block for Public Subnets"
  default = {
    devel   = ["10.37.10.0/24","10.37.11.0/24","10.37.12.0/24"]
    staging = ["10.117.10.0/24","10.117.11.0/24","10.117.12.0/24"]
    prod    = ["10.127.10.0/24","10.127.11.0/24","10.127.12.0/24"]
  }
}

variable "azs" {
  type        = "map"
  description = "Availability zones per region"
  default = {
    us-east-2      = ["us-east-2a","us-east-2b","us-east-2c"]
    ap-south-1     = ["ap-south-1a","ap-south-1b","ap-south-1c"]
    ap-southeast-1 = ["ap-southeast-1a","ap-southeast-1b","ap-southeast-1c"]
  }
}

variable "elb_sg" {
  type        = "map"
  description = "Name of the application ELB security group"
  default = {
    devel   = "ecs-devel-cluster-external-sg"
    staging = "ecs-staging-cluster-external-sg"
    prod    = "ecs-prod-cluster-external-sg"
  }
}

variable "elb_name" {
  type        = "map"
  description = "Name of the application ELB"
  default = {
    devel     = "ecs-devel-cluster-external"
    staging   = "ecs-staging-cluster-external"
    prod      = "ecs-prod-cluster-external"
  }
}

variable "services" {
  type        = "list"
  description = "Name of all the ECR repositories"
  default     = ["access-service","apigateway","config","notification-consumer","ell","outlet-service","loyalty","feedback-module","map-service","notification-producer","retailer-module","sshd"]
}

variable "apigateway" {
  type        = "map"
  description = "Name of the apigateway public DNS"
  default = {
    devel   = "develapigateway.bizom.in"
    staging = "stagingapigateway.bizom.in"
    prod    = "apigateway.bizom.in"
  }
}

variable "certificate_arn" {
  type        = "map"
  description = "Name of the certificate ARN in the region"
  default = {
    us-east-2      = "arn:aws:acm:us-east-2:596849958460:certificate/e6fe675f-290d-46c9-8e71-1e9c6da46764"
    ap-south-1     = "arn:aws:acm:ap-south-1:596849958460:certificate/dbb069e0-f701-4a9e-aa50-ac55f8fd50c7"
    ap-southeast-1 = "arn:aws:acm:ap-southeast-1:596849958460:certificate/f24e5771-c423-4679-bbed-c3799e9557b5"
  }
}

variable "pm2_env" {
  type        = "map"
  description = "Name of the pm2 environment to use"
  default = {
    devel     = "development"
    staging   = "staging"
    prod      = "production"
  }
}

variable "bitbucket_credentials" {
  type        = "map"
  description = "Credentials for the bitbucket"
  default = {
    username = ""
    password = ""
  }
}
