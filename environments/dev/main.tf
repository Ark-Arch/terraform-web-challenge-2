module "networking" {
  source = "../../modules/networking"
  azs = var.azs
  vpc_cidr = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment = var.environment
  webapp_count = var.webapp_count
  nat_ami = var.nat_ami
}