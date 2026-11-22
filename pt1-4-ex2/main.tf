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
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Red
# ---------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "pt1-4-ex2-vpc"
  }
}

# ---------------------------------------------------------------------------
# Subredes
# ---------------------------------------------------------------------------
resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.32.0/25"
  availability_zone = "us-east-1a"

  tags = {
    Name = "pt1-4-ex2-subnet-a"
  }
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.30.0/23"
  availability_zone = "us-east-1a"

  tags = {
    Name = "pt1-4-ex2-subnet-b"
  }
}

resource "aws_subnet" "c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.33.0/28"
  availability_zone = "us-east-1a"

  tags = {
    Name = "pt1-4-ex2-subnet-c"
  }
}

# ---------------------------------------------------------------------------
# Instancias EC2: 2 por subred
# ---------------------------------------------------------------------------
resource "aws_instance" "a1" {
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.a.id

  tags = {
    Name = "pt1-4-ex2-a1"
  }
}

resource "aws_instance" "a2" {
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.a.id

  tags = {
    Name = "pt1-4-ex2-a2"
  }
}

resource "aws_instance" "b1" {
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.b.id

  tags = {
    Name = "pt1-4-ex2-b1"
  }
}

resource "aws_instance" "b2" {
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.b.id

  tags = {
    Name = "pt1-4-ex2-b2"
  }
}

resource "aws_instance" "c1" {
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.c.id

  tags = {
    Name = "pt1-4-ex2-c1"
  }
}

resource "aws_instance" "c2" {
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.c.id

  tags = {
    Name = "pt1-4-ex2-c2"
  }
}