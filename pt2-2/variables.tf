# ---------------------------------------------------------------------------
# Proveedor
# ---------------------------------------------------------------------------
variable "aws_region" {
  description = "Región de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

# ---------------------------------------------------------------------------
# Red
# ---------------------------------------------------------------------------
variable "vpc_name" {
  description = "Nombre (etiqueta Name) de la VPC"
  type        = string
  default     = "VPC-03"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR de Public Subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR de Public Subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_subnet_a_az" {
  description = "Zona de disponibilidad de Public Subnet A"
  type        = string
  default     = "us-east-1a"
}

variable "public_subnet_b_az" {
  description = "Zona de disponibilidad de Public Subnet B"
  type        = string
  default     = "us-east-1b"
}

# ---------------------------------------------------------------------------
# Instancias EC2
# ---------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI de Amazon Linux usada por las instancias EC2"
  type        = string
  default     = "ami-0aacbf72109c53c0c"
}

variable "key_name" {
  description = "Par de claves SSH existente en AWS"
  type        = string
  default     = "vockey"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}
