terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "sa-east-1"
}

# Create a VPC
resource "aws_vpc" "SCDOA" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my-SCDOA-vpc"
  }
}

resource "aws_subnet" "SCDOA-public-subnet1" {
  vpc_id            = aws_vpc.SCDOA.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "my-SCDOA-public-subnet1"
  }
}

resource "aws_subnet" "SCDOA-public-subnet2" {
  vpc_id            = aws_vpc.SCDOA.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "sa-east-1b"

  tags = {
    Name = "my-SCDOA-public-subnet2"
  }
}

resource "aws_subnet" "SCDOA-private-subnet1" {
  vpc_id            = aws_vpc.SCDOA.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "my-SCDOA-private-subnet1"
  }
}

resource "aws_subnet" "SCDOA-private-subnet2" {
  vpc_id            = aws_vpc.SCDOA.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "sa-east-1b"

  tags = {
    Name = "my-SCDOA-private-subnet2"
  }
}

resource "aws_internet_gateway" "SCDOA-gw" {
  vpc_id = aws_vpc.SCDOA.id

  tags = {
    Name = "my-SCDOA-gw"
  }
}

resource "aws_route_table" "SCDOA-public-route" {
  vpc_id = aws_vpc.SCDOA.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.SCDOA-gw.id
  }

  tags = {
    Name = "my-SCDOA-public-route"
  }
}

resource "aws_route_table_association" "SCDOA-public-subnet1-association" {
  subnet_id      = aws_subnet.SCDOA-public-subnet1.id
  route_table_id = aws_route_table.SCDOA-public-route.id
}

resource "aws_route_table_association" "SCDOA-public-subnet2-association" {
  subnet_id      = aws_subnet.SCDOA-public-subnet2.id
  route_table_id = aws_route_table.SCDOA-public-route.id
}

resource "aws_route_table" "SCDOA-private-route" {
  vpc_id = aws_vpc.SCDOA.id

  tags = {
    Name = "my-SCDOA-private-route"
  }
}

resource "aws_route_table_association" "SCDOA-private-subnet1-association" {
  subnet_id      = aws_subnet.SCDOA-private-subnet1.id
  route_table_id = aws_route_table.SCDOA-private-route.id
}

resource "aws_route_table_association" "SCDOA-private-subnet2-association" {
  subnet_id      = aws_subnet.SCDOA-private-subnet2.id
  route_table_id = aws_route_table.SCDOA-private-route.id
}

# Create a security group for RDS
resource "aws_security_group" "SCDOA-rds-sg" {
  vpc_id = aws_vpc.SCDOA.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-SCDOA-rds-sg"
  }
}

# Create the RDS Subnet Group
resource "aws_db_subnet_group" "SCDOA-rds-subnet-group" {
  name       = "my-scdoa-rds-subnet-group"
  subnet_ids = [
    aws_subnet.SCDOA-private-subnet1.id,
    aws_subnet.SCDOA-private-subnet2.id
  ]

  tags = {
    Name = "my-SCDOA-rds-subnet-group"
  }
}

# Create the RDS PostgreSQL Instance
resource "aws_db_instance" "scdoadata-dev" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.1"  # Ensure this version is correct and supported
  instance_class         = "db.t3.micro"
  username               = "scdoamodb"  # Changed username to a non-reserved word
  password               = "scdoadev"
  parameter_group_name   = "default.postgres16"  # Updated to a valid PostgreSQL version
  db_subnet_group_name   = aws_db_subnet_group.SCDOA-rds-subnet-group.name
  vpc_security_group_ids = [aws_security_group.SCDOA-rds-sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = "my-SCDOA-rds"
  }
}

resource "aws_s3_bucket" "awsdevops120624" {
  bucket = "awsdevops120624"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "DELETE", "GET"]
    allowed_origins = ["*"]
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "DELETE", "GET"]
    allowed_origins = ["*"]
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "awsdevops120624_ownership" {
  bucket = aws_s3_bucket.awsdevops120624.bucket

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "awsdevops120624_public_access" {
  bucket = aws_s3_bucket.awsdevops120624.bucket

  block_public_acls   = false
  block_public_policy = false
  ignore_public_acls  = false
  restrict_public_buckets = false
}