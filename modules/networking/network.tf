# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.profile}-vpc"
  }
}

# Create Public subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = var.public_subnets_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet-${count.index + 0}"
  }
}

# Create Private subnets
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = var.private_subnets_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "private subnet-${count.index + 0}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "internet gateway"
  }
}

# Create Public Route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "public route table"
  }
}

# Create Private Route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private route table"
  }
}

# Create Public Route Table Assocation
resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Create Private Route Table Assocation
resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# Create Public Route
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# Create Security group
resource "aws_security_group" "application_sg" {
  name        = "application-sg"
  description = "Security group for EC2 instance with web application"
  vpc_id = aws_vpc.my_vpc.id
  depends_on  = [aws_vpc.my_vpc]

  ingress {
    protocol    = "tcp"
    from_port   = "22"
    to_port     = "22"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = "80"
    to_port     = "80"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = "443"
    to_port     = "443"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = var.DB_PORT
    to_port     = var.DB_PORT
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "application-sg"
  }
}

# Create EC2 instance

resource "aws_instance" "ec2" {
  ami                  = var.ami
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public_subnet[0].id
  key_name             = var.key_name
  security_groups      = [aws_security_group.application_sg.id]
  disable_api_termination = false
  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_type           = var.instance_vol_type
    volume_size           = var.instance_vol_size
    delete_on_termination = true
  }
    user_data = <<EOF
#!/bin/bash
echo export DB_NAME=${var.DB_NAME} >> /etc/environment
echo export DB_USER=${var.DB_USER} >> /etc/environment
echo export DB_PASSWORD=${var.DB_PASSWORD} >> /etc/environment
echo export DB_HOST="${var.DB_HOST} >> /etc/environment
echo export DB_PORT=${var.DB_PORT} >> /etc/environment
EOF
tags = {
    "Name" = "ec2"
  }
}