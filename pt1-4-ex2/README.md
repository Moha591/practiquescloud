# Ejercicio 2 — VPC, subredes y EC2

## Diseño

- VPC: `10.0.0.0/16`.
- Tres subredes en `us-east-1a`:
  - Subred A: `10.0.32.0/25`.
  - Subred B: `10.0.30.0/23`.
  - Subred C: `10.0.33.0/28`.
- Seis instancias EC2 `t3.micro` con Amazon Linux 2023, dos por subred.

Cada instancia tiene asignada explícitamente su subred mediante `subnet_id`.

Terraform crea únicamente la VPC, las tres subredes y las seis instancias. No se
declaran Security Groups, pares de claves, Internet Gateway, tablas de rutas,
IPs públicas, variables ni outputs.

## Uso

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Para eliminar los recursos:

```bash
terraform destroy
```
