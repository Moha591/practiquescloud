provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "instanciauno" {
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"

  tags = {
    Name = "instanciauno"
  }
}

resource "aws_instance" "instanciados" {
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"

  tags = {
    Name = "instanciados"
  }
}