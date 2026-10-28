variable "aws_region" {
  description = "Región de AWS donde se despliega la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC principal."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone" {
  description = "Zona de disponibilidad común a las tres subredes."
  type        = string
  default     = "us-east-1a"
}

variable "ami_id" {
  description = "AMI de Amazon Linux 2023 en us-east-1 (la misma que en pt1-4-ex1)."
  type        = string
  default     = "ami-04b938437b69a2c9c"
}

variable "instance_type" {
  description = "Tipo de instancia EC2."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre del par de claves EC2 que se importa en AWS."
  type        = string
  default     = "labuser"
}

variable "ssh_cidr" {
  description = "CIDR autorizado para SSH (IP pública del alumno con /32)."
  type        = string
  default     = "81.42.248.211/32"
}

variable "subnets" {
  description = "Mapa de subredes: clave, CIDR y nombre lógico."
  type = map(object({
    cidr_block = string
    name       = string
  }))
  default = {
    A = {
      cidr_block = "10.0.32.0/25"
      name       = "subnet-a"
    }
    B = {
      cidr_block = "10.0.30.0/23"
      name       = "subnet-b"
    }
    C = {
      cidr_block = "10.0.33.0/28"
      name       = "subnet-c"
    }
  }
}
