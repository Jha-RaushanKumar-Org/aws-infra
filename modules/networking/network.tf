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
  vpc_id      = aws_vpc.my_vpc.id
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
    from_port   = "3000"
    to_port     = "3000"
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
  ami                     = var.ami
  instance_type           = var.instance_type
  subnet_id               = aws_subnet.public_subnet[0].id
  key_name                = var.key_name
  security_groups         = [aws_security_group.application_sg.id]
  disable_api_termination = false
  iam_instance_profile    = aws_iam_instance_profile.app_instance_profile.name
  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_type           = var.instance_vol_type
    volume_size           = var.instance_vol_size
    delete_on_termination = true
  }
  #   code for the user data
  user_data = <<EOF

#!/bin/bash

echo "export DB_USER=${var.database_username} " >> /home/ec2-user/webapp/.env
echo "export DB_PASSWORD=${var.database_password} " >> /home/ec2-user/webapp/.env
echo "export DB_PORT=${var.port} " >> /home/ec2-user/webapp/.env
echo "export DB_HOST=$(echo ${aws_db_instance.db_instance.endpoint} | cut -d: -f1)" >> /home/ec2-user/webapp/.env
echo "export DB_NAME=${var.database_name} " >> /home/ec2-user/webapp/.env
echo "export BUCKET_NAME=${aws_s3_bucket.mybucket.bucket} " >> /home/ec2-user/webapp/.env
echo "export BUCKET_REGION=${var.region} " >> /home/ec2-user/webapp/.env
sudo chmod +x setenv.sh
sh setenv.sh

 EOF

  tags = {
    "Name" = "ec2"
  }
}

#Create database security group
resource "aws_security_group" "database" {
  name        = "database"
  description = "Security group for RDS instance for database"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    protocol        = "tcp"
    from_port       = "3306"
    to_port         = "3306"
    security_groups = [aws_security_group.application_sg.id]
  }

  tags = {
    "Name" = "database-sg"
  }
}


resource "random_id" "id" {
  byte_length = 8
}
#Create s3 bucket
resource "aws_s3_bucket" "mybucket" {
  bucket        = "mywebappbucket-${random_id.id.hex}"
  acl           = "private"
  force_destroy = true
  lifecycle_rule {
    id      = "StorageTransitionRule"
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}

#Create iam policy to accress s3
resource "aws_iam_policy" "WebAppS3_policy" {
  name = "WebAppS3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.mybucket.bucket}/*"
        Resource = "arn:aws:s3:::${aws_s3_bucket.mybucket.bucket}/*"
      }
    ]
  })
}

#Create iam role for ec2 to access s3
resource "aws_iam_role" "WebAppS3_role" {
  name = "EC2-CSYE6225"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

#Create iam role policy attachment
resource "aws_iam_role_policy_attachment" "WebAppS3_role_policy_attachment" {
  role       = aws_iam_role.WebAppS3_role.name
  policy_arn = aws_iam_policy.WebAppS3_policy.arn
}

#attach iam role to ec2 instance
resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "app_instance_profile"
  role = aws_iam_role.WebAppS3_role.name
}

#Create Rds subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "db_subnet_group"
  description = "RDS subnet group for database"
  subnet_ids  = aws_subnet.private_subnet.*.id
  tags = {
    Name = "db_subnet_group"
  }
}

#Create Rds parameter group
resource "aws_db_parameter_group" "db_parameter_group" {
  name        = "db-parameter-group"
  family      = "mysql8.0"
  description = "RDS parameter group for database"
  parameter {
    name  = "character_set_server"
    value = "utf8"
  }
}

#Create Rds instance
resource "aws_db_instance" "db_instance" {
  identifier                = var.db_identifier
  engine                    = "mysql"
  engine_version            = "8.0.28"
  instance_class            = "db.t3.micro"
  name                      = var.database_name
  username                  = var.database_username
  password                  = var.database_password
  parameter_group_name      = aws_db_parameter_group.db_parameter_group.name
  allocated_storage         = 20
  storage_type              = "gp2"
  multi_az                  = false
  skip_final_snapshot       = true
  final_snapshot_identifier = "final-snapshot"
  publicly_accessible       = false
  db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.database.id]
  tags = {
    Name = "db_instance"
  }
}
