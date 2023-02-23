module "mynetwork" {
  source = "./modules/networking"

  vpc_cidr_block         = var.vpc_cidr_block
  profile                = var.profile
  region                 = var.region
  public_subnets_cidr    = var.public_subnets_cidr
  private_subnets_cidr   = var.private_subnets_cidr
  availability_zones     = local.production_availability_zones
  destination_cidr_block = var.destination_cidr_block
  DB_NAME                = var.DB_NAME
  DB_USER                = var.DB_USER
  DB_PASSWORD            = var.DB_PASSWORD
  DB_HOST                = var.DB_HOST
  DB_PORT                = var.DB_PORT
  ami                    = var.ami
  instance_type          = var.instance_type
  instance_vol_type      = var.instance_vol_type
  instance_vol_size      = var.instance_vol_size
  key_name               = var.key_name
}
locals {
  production_availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}
