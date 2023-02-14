variable "profile" {
  description = "Profile for CLI"
}

variable "region" {
  description = "AWS region"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
}

variable "public_subnets_cidr" {
  description = "Public subnets cidr"
}

variable "private_subnets_cidr" {
  description = "Private subnets cidr"
}

variable "availability_zones" {
  description = "Availability zone"
}

variable "destination_cidr_block" {
  description = "Destination public cidr"
}
