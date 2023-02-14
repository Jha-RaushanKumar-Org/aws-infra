module "mynetwork" {
  source = "./modules/networking"

  vpc_cidr_block         = var.vpc_cidr_block
  profile                = var.profile
  region                 = var.region
  public_subnets_cidr    = var.public_subnets_cidr
  private_subnets_cidr   = var.private_subnets_cidr
  availability_zones     = local.production_availability_zones
  destination_cidr_block = var.destination_cidr_block
}
locals {
  production_availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}
