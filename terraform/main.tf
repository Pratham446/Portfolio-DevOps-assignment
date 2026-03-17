# ============================================================
# SECURE main.tf — DevSecOps Assignment (FIXED VERSION)
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# ─── VPC ────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# ─── Internet Gateway ───────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# ─── Public Subnet (LIMITED USE) ────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false   # 🔐 FIXED

  tags = {
    Name    = "${var.project_name}-public-subnet"
    Project = var.project_name
  }
}

# ─── Route Table ────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─── Security Group (SECURED) ───────────────────────────────
resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg"
  description = "Secure SG for web app"
  vpc_id      = aws_vpc.main.id

  # 🔐 SSH only from YOUR IP
  ingress {
    description = "SSH restricted"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["13.127.174.60/32"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # App port
  ingress {
    description = "App"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 🔐 Restricted outbound (NO full open)
  egress {
    description = "HTTPS only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# ─── Key Pair ───────────────────────────────────────────────
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = var.public_key

  tags = {
    Project = var.project_name
  }
}

# ─── EC2 Instance (SECURED) ─────────────────────────────────
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name

  # 🔐 IMDSv2 ENABLED
  metadata_options {
    http_tokens = "required"
  }

  # 🔐 ENCRYPTED STORAGE
  root_block_device {
    encrypted = true
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu
    docker pull python:3.11-slim
  EOF

  tags = {
    Name    = "${var.project_name}-server"
    Project = var.project_name
  }
}

# ─── VPC FLOW LOGS (SECURITY) ───────────────────────────────
resource "aws_flow_log" "vpc_flow_log" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_group_name       = "/aws/vpc/flowlogs"
}
