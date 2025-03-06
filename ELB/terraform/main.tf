provider "aws" {
  region = var.aws_region
}

module "network" {
  source      = "./modules/network"
  vpc_cidr    = var.vpc_cidr
  subnet_cidr = var.subnet_cidr
}

module "compute" {
  source        = "./modules/compute"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = module.network.subnet_id
}
