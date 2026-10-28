output "vpc_id" {
  description = "ID de la VPC creada."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Bloque CIDR de la VPC."
  value       = aws_vpc.this.cidr_block
}

output "subnet_ids" {
  description = "IDs de las subredes, indexados por clave (A, B, C)."
  value = {
    for key, subnet in aws_subnet.this : key => subnet.id
  }
}

output "subnet_cidrs" {
  description = "CIDR de cada subred, indexado por clave (A, B, C)."
  value = {
    for key, subnet in aws_subnet.this : key => subnet.cidr_block
  }
}

output "security_group_id" {
  description = "ID del grupo de seguridad común."
  value       = aws_security_group.this.id
}

output "key_name" {
  description = "Nombre del par de claves EC2 asociado a las instancias."
  value       = aws_key_pair.this.key_name
}

output "instance_ids" {
  description = "IDs de las 6 instancias EC2, indexados por nombre."
  value = {
    for name, instance in aws_instance.this : name => instance.id
  }
}

output "instance_private_ips" {
  description = "IPs privadas de las 6 instancias, indexadas por nombre."
  value = {
    for name, instance in aws_instance.this : name => instance.private_ip
  }
}

output "instance_summary" {
  description = "Resumen de cada instancia: ID, IP privada, subred, estado y tipo."
  value = {
    for name, instance in aws_instance.this : name => {
      id         = instance.id
      private_ip = instance.private_ip
      subnet_id  = instance.subnet_id
      state      = instance.instance_state
      type       = instance.instance_type
    }
  }
}
