# environment
variable "environment" {
    description = "Enironment - dev vs prod"  
    type = string
}

# vpc variable
variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type = string  
}

# public subnet ciders
variable "public_subnet_cidrs" {
    description = "CIDR blocks for public subnets"
    type = list(string)
}

variable "private_subnet_cidrs" {
    description = "CIDR blocks for private subnets"
    type = list(string)
}

variable "azs" {
    description = "Availability Zones"
    type = list(string)  
}

variable "nat_ami" {
    description = "custome nat"
    type = string 
}

variable "create_nat_route_for_web" {
  description = "Whether to create NAT route for web/app subnets"
  type        = bool
  default     = true
}

variable "create_nat_route_for_db" {
  description = "Whether to create NAT route for db subnets"
  type        = bool
  default     = false
}

variable "webapp_count" {
    type = number
    description = "the number of web applications to tbe deployed"  
}

