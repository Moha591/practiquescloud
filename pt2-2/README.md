# Pt2.2 — IGW, RTB i SG

## Objetivo

Crear con Terraform una infraestructura básica en AWS compuesta por una VPC, dos
subredes públicas, un Internet Gateway, una tabla de rutas pública, un Security Group
y dos instancias EC2, siguiendo los requisitos de la práctica **Pt2.2**.

## Arquitectura

| Recurso | Nombre | Configuración |
|---|---|---|
| Región | — | `us-east-1` |
| VPC | `VPC-03` | `10.0.0.0/16` |
| Subred pública A | `Public Subnet A` | `10.0.1.0/24`, `us-east-1a`, IP pública automática |
| Subred pública B | `Public Subnet B` | `10.0.2.0/24`, `us-east-1b`, IP pública automática |
| Internet Gateway | `VPC-03-igw` | Asociado a `VPC-03` |
| Tabla de rutas | `VPC-03-public-rtb` | `0.0.0.0/0` → Internet Gateway |
| Security Group | `VPC-03-sg` | SSH, ICMP y salida |
| Instancia A | `ec2-a` | `t3.micro`, Amazon Linux, `Public Subnet A`, clave `vockey` |
| Instancia B | `ec2-b` | `t3.micro`, Amazon Linux, `Public Subnet B`, clave `vockey` |

### Reglas del Security Group

| Dirección | Protocolo / puerto | Origen / destino | Descripción |
|---|---|---|---|
| Entrada | TCP `22` | `0.0.0.0/0` | SSH desde cualquier origen |
| Entrada | ICMP (`-1`) | `10.0.0.0/16` | Ping solo desde dentro de la VPC |
| Salida | Todos (`-1`) | `0.0.0.0/0` | Todo el tráfico saliente |

## Estructura del proyecto

```text
pt2-2/
├── assets/
│   └── .gitkeep
├── .gitignore
├── README.md
├── main.tf                  # VPC, subredes, IGW, RTB, SG e instancias EC2
├── outputs.tf               # IDs e IPs públicas de los recursos
├── terraform.tfvars.example # Ejemplo de variables locales
├── variables.tf             # Variables con valores por defecto
└── versions.tf              # Versión de Terraform y proveedor AWS
```

## Requisitos previos

- Terraform `>= 1.3.0`.
- Credenciales de AWS configuradas (por ejemplo, AWS Academy Learner Lab).
- Par de claves `vockey` disponible en `us-east-1`.
- La AMI usada es `ami-0aacbf72109c53c0c` (Amazon Linux, `us-east-1`). Se puede
  cambiar con la variable `ami_id`.

## Despliegue

Desde la carpeta `pt2-2`:

```bash
# 1. Descargar el proveedor de AWS
terraform init

# 2. Comprobar formato y sintaxis
terraform fmt -check
terraform validate

# 3. Revisar el plan
terraform plan -out=tfplan

# 4. Crear la infraestructura
terraform apply tfplan
```

Si se quieren cambiar valores (región, CIDR, tipo de instancia, etc.), copiar el
archivo de ejemplo y editarlo:

```bash
cp terraform.tfvars.example terraform.tfvars
```

## Verificación

Consultar las salidas de Terraform:

```bash
terraform output
```

Comprobar los recursos con AWS CLI:

```bash
# VPC
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=VPC-03" \
  --query "Vpcs[].{ID:VpcId,CIDR:CidrBlock,Estado:State}" \
  --output table

# Subredes
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "Subnets[].{ID:SubnetId,Nombre:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,AZ:AvailabilityZone,IPPublica:MapPublicIpOnLaunch}" \
  --output table

# Instancias
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].{ID:InstanceId,Nombre:Tags[?Key=='Name']|[0].Value,Tipo:InstanceType,Subred:SubnetId,IPPublica:PublicIpAddress,Clave:KeyName}" \
  --output table

# Security Group
aws ec2 describe-security-groups \
  --group-ids "$(terraform output -raw security_group_id)" \
  --query "SecurityGroups[].IpPermissions" \
  --output json
```

También se puede comprobar desde la consola de AWS:

- **VPC → Your VPCs** para ver `VPC-03`.
- **VPC → Subnets** para ver `Public Subnet A` y `Public Subnet B`.
- **VPC → Internet gateways** para ver `VPC-03-igw`.
- **VPC → Route tables** para ver `VPC-03-public-rtb` y sus asociaciones.
- **EC2 → Security Groups** para ver `VPC-03-sg`.
- **EC2 → Instances** para ver `ec2-a` y `ec2-b` en estado `running`.

Prueba de conectividad (cuando las instancias estén en ejecución):

```bash
ping <IP_PUBLICA_EC2_A>
ssh -i vockey.pem ec2-user@<IP_PUBLICA_EC2_A>
```

## Capturas para la memoria

Guardar en `assets/` las imágenes solicitadas en la entrega:

| Archivo sugerido | Contenido |
|---|---|
| `assets/vpc_subnets.png` | VPC `VPC-03` y las dos subredes públicas |
| `assets/igw_rtb.png` | Internet Gateway y tabla de rutas con `0.0.0.0/0` |
| `assets/security_group.png` | Reglas de entrada y salida del Security Group |
| `assets/ec2_instances.png` | `ec2-a` y `ec2-b` en ejecución con IP pública |

## Limpieza de recursos

Para evitar cargos, destruir toda la infraestructura al terminar:

```bash
terraform plan -destroy
terraform destroy
```

El `destroy` elimina las dos instancias, el Security Group, la tabla de rutas, el
Internet Gateway, las subredes y la VPC.

## Notas

- Las dos subredes tienen `map_public_ip_on_launch = true`, por lo que las instancias
  reciben IP pública automáticamente.
- Las instancias usan la clave `vockey`, disponible en los entornos de AWS Academy.
- El Security Group permite ICMP únicamente desde `10.0.0.0/16`; no se abre ICMP a
  Internet.
- El estado de Terraform (`terraform.tfstate`) y los archivos `*.tfvars` están
  excluidos por `.gitignore`.
- No se ha ejecutado `terraform apply`: esta carpeta contiene únicamente el código y
  la documentación preparados para el despliegue.
