output "vpc_id" {
  description = "ID de la VPC VPC-03"
  value       = aws_vpc.this.id
}

output "public_subnet_a_id" {
  description = "ID de Public Subnet A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "ID de Public Subnet B"
  value       = aws_subnet.public_b.id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "ID de la tabla de rutas pública"
  value       = aws_route_table.public.id
}

output "security_group_id" {
  description = "ID del Security Group"
  value       = aws_security_group.this.id
}

output "ec2_a_public_ip" {
  description = "IP pública de ec2-a"
  value       = aws_instance.ec2_a.public_ip
}

output "ec2_b_public_ip" {
  description = "IP pública de ec2-b"
  value       = aws_instance.ec2_b.public_ip
}
