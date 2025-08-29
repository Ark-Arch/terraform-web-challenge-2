variable "aws_region" {
    type = string
    description = "aws region"
}

variable "azs" {}
variable "vpc_cidr" {}
variable "public_subnet_cidrs" {
}
variable "private_subnet_cidrs" {
  
}
variable "environment" {
  
}
variable "webapp_count" {
}

variable "nat_ami" {
}