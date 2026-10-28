terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "pt1-4-ex2-vpc"
    Project = "pt1-4-ex2"
  }
}

# ---------------------------------------------------------------------------
# Subredes: las tres comparten la misma zona de disponibilidad (us-east-1a)
# ---------------------------------------------------------------------------
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name    = "pt1-4-ex2-${each.value.name}"
    Project = "pt1-4-ex2"
    Subnet  = each.key
  }
}

# ---------------------------------------------------------------------------
# Salida a Internet: IGW + tabla de rutas pública
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name    = "pt1-4-ex2-igw"
    Project = "pt1-4-ex2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name    = "pt1-4-ex2-rt-public"
    Project = "pt1-4-ex2"
  }
}

resource "aws_route_table_association" "this" {
  for_each = aws_subnet.this

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Par de claves para SSH. La clave privada (labuser.pem) se genera localmente
# y no se versiona; aquí solo se importa la clave pública.
# ---------------------------------------------------------------------------
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file("${path.module}/labuser.pub")

  tags = {
    Name    = var.key_name
    Project = "pt1-4-ex2"
  }
}

# ---------------------------------------------------------------------------
# Grupo de seguridad común a las 6 instancias.
# Permite SSH únicamente desde la IP indicada en ssh_cidr.
# ---------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "pt1-4-ex2-sg"
  description = "Security group del ejercicio 2: SSH desde la IP autorizada"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH desde la IP autorizada"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "pt1-4-ex2-sg"
    Project = "pt1-4-ex2"
  }
}

# ---------------------------------------------------------------------------
# 6 instancias EC2: 2 por cada subred
# ---------------------------------------------------------------------------
locals {
  instances = {
    "ec2-a-1" = "A"
    "ec2-a-2" = "A"
    "ec2-b-1" = "B"
    "ec2-b-2" = "B"
    "ec2-c-1" = "C"
    "ec2-c-2" = "C"
  }
}

resource "aws_instance" "this" {
  for_each = local.instances

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.this[each.value].id
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true

  tags = {
    Name    = "pt1-4-ex2-${each.key}"
    Project = "pt1-4-ex2"
    Subnet  = each.value
  }
}
