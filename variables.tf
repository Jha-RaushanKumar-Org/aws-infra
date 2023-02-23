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

variable "destination_cidr_block" {
  description = "Destination public cidr"
}

variable "DB_NAME" {
  description = "DB name"
}

variable "DB_USER" {
  description = "DB username"
}

variable "DB_PASSWORD" {
  description = "DB password"
}

variable "DB_HOST" {
  description = "DB host"
}

variable "DB_PORT" {
  description = "DB port"
}

variable "ami" {
  description = "AMI"
}

variable "instance_type" {
  description = "EC2 instance type"
}

variable "instance_vol_type" {
  description = "EC2 volume type"
}

variable "instance_vol_size" {
  description = "EC2 volume size"
}

variable "key_name" {
  description = "Name of ssh key"
}