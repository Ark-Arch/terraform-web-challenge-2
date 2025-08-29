# used to record non-secret configs
# but secret configs should be kept as environment variables

aws_region = "eu-west-1"
azs = ["eu-west-1a", "eu-west-1b"]
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.0.0/20","10.0.16.0/20"]
private_subnet_cidrs = ["10.0.32.0/20","10.0.48.0/20"]
environment = "dev"
webapp_count = 2
nat_ami = "ami-0bc691261a82b32bc"

