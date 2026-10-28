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
# Subredes privadas: las tres comparten la misma zona de disponibilidad
# (us-east-1a). No se asigna IP pública automática.
# ---------------------------------------------------------------------------
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name    = "pt1-4-ex2-${each.value.name}"
    Project = "pt1-4-ex2"
    Subnet  = each.key
  }
}

# ---------------------------------------------------------------------------
# Par de claves para futuras prácticas. La clave privada (labuser.pem) se
# genera localmente y no se versiona; aquí solo se importa la clave pública.
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
# Sin reglas de entrada: las instancias no son accesibles desde Internet.
# ---------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "pt1-4-ex2-sg"
  description = "Security group del ejercicio 2: sin reglas de entrada"
  vpc_id      = aws_vpc.this.id

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
# 6 instancias EC2: 2 por cada subred, sin IP pública
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
  associate_public_ip_address = false

  tags = {
    Name    = "pt1-4-ex2-${each.key}"
    Project = "pt1-4-ex2"
    Subnet  = each.value
  }
}
