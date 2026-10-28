# Ejercicio 2 — Diseño y despliegue de VPC, subredes y EC2 (Consola + IaC)

## Objetivo

Comprender la segmentación de redes en AWS mediante una VPC con tres subredes y
comparar dos formas de despliegue:

- **Parte B:** despliegue manual desde la consola de AWS.
- **Parte C:** despliegue automatizado con Terraform (IaC).

Las tres subredes se encuentran en la misma zona de disponibilidad (`us-east-1a`) y
en cada una se despliegan dos instancias EC2 `t3.micro` con Amazon Linux 2023, hasta
un total de **6 instancias**.

La infraestructura desplegada es pública: incluye una puerta de enlace de Internet (IGW), una tabla de
rutas con salida a Internet, IP pública en cada instancia y acceso SSH restringido a
la IP del alumno mediante el par de claves `labuser`.

## Diseño de red

| Subred | CIDR | Zona | Tipo | Direcciones | Usables | Instancias |
|---|---|---|---|---|---|---|
| Subred A | `10.0.32.0/25` | `us-east-1a` | Pública | 128 | 123 | 2 |
| Subred B | `10.0.30.0/23` | `us-east-1a` | Pública | 512 | 507 | 2 |
| Subred C | `10.0.33.0/28` | `us-east-1a` | Pública | 16 | 11 | 2 |
| **Total** | **VPC `10.0.0.0/16`** | | | | | **6** |

AWS reserva 5 direcciones en cada subred (red, router, DNS, futuras y broadcast), por
eso el número de direcciones usables es el total menos cinco.

Los rangos no se solapan:

- Subred A: `10.0.32.0` — `10.0.32.127`
- Subred B: `10.0.30.0` — `10.0.31.255`
- Subred C: `10.0.33.0` — `10.0.33.15`

Todos los rangos pertenecen a la VPC `10.0.0.0/16`.

Las tres subredes son públicas: tienen `map_public_ip_on_launch = true` y están
asociadas a la tabla de rutas `pt1-4-ex2-rt-public`, que envía `0.0.0.0/0` al
puerta de enlace de Internet (IGW) `pt1-4-ex2-igw`.

## Topología

![Topología de la VPC y las subredes](assets/topologia.png)

El tráfico de entrada y salida sigue el camino **Internet → puerta de enlace de Internet (IGW) →
tabla de rutas → subredes públicas**. Cada subred aloja dos instancias EC2 con IP
privada e IP pública. Todas comparten el grupo de seguridad `pt1-4-ex2-sg`, que solo
permite SSH desde `81.42.248.211/32`, y el par de claves `labuser`.

El diagrama editable se encuentra en
[`assets/topologia.drawio`](assets/topologia.drawio) y se ha exportado a
[`assets/topologia.png`](assets/topologia.png).

## Parte A — Diseño de la red

La VPC y las subredes se han diseñado con los siguientes criterios:

- Una VPC principal con bloque `10.0.0.0/16`.
- Tres subredes de tamaños diferentes para practicar el cálculo de CIDR.
- Las tres subredes en la misma AZ (`us-east-1a`), tal como pide el enunciado.
- Dos instancias EC2 por subred, con un total de seis.
- Sin solapamientos entre subredes.
- Salida a Internet mediante una puerta de enlace de Internet (IGW) y una tabla de rutas pública.
- IP pública automática en cada instancia.
- Grupo de seguridad común con SSH restringido a la IP del alumno.
- Par de claves `labuser` para el acceso SSH.
- Etiquetas `Project = pt1-4-ex2` para localizar todos los recursos.

## Parte B — Despliegue por consola de AWS

El despliegue manual se realiza desde la consola de AWS con estos pasos:

1. **Crear la VPC:** `VPC → Your VPCs → Create VPC`, seleccionando solo la VPC
   (sin subredes automáticas), con nombre `pt1-4-ex2-vpc` y CIDR `10.0.0.0/16`.
   Activar el soporte DNS y los nombres de host DNS.
2. **Crear las subredes:** `VPC → Subnets → Create subnet`, seleccionando la VPC
   anterior, la AZ `us-east-1a` y los CIDR `10.0.32.0/25`, `10.0.30.0/23` y
   `10.0.33.0/28`. Activar la asignación automática de IP pública.
3. **Crear la puerta de enlace de Internet (IGW):** `VPC → Internet gateways → Create internet gateway`,
   asociarlo a la VPC y crear una tabla de rutas con `0.0.0.0/0 → IGW`. Asociar la
   tabla a las tres subredes.
4. **Crear el grupo de seguridad:** `EC2 → Security groups → Create security group` en la
   VPC, con una regla de entrada SSH (puerto 22) limitada a la IP pública del alumno
   con máscara `/32`. La salida puede quedar abierta.
5. **Crear el par de claves:** `EC2 → Key pairs → Create key pair`, tipo RSA, formato
   `.pem`, nombre `labuser`. Descargar `labuser.pem` y guardarlo en un lugar seguro.
6. **Crear las instancias:** `EC2 → Instances → Launch instances`, con Amazon Linux
   2023, tipo `t3.micro`, la VPC y la subred correspondiente. Se crean dos instancias
   por subred, con el par de claves `labuser`, el grupo de seguridad del ejercicio y IP
   pública automática.
7. **Etiquetar los recursos** con `Project = pt1-4-ex2` para poder filtrarlos.
8. **Tomar las capturas** de la VPC, las subredes y el listado de las seis instancias.

### Resumen de la VPC y las subredes

![Resumen de la VPC y las subredes](assets/vpc_subnets.png)

### Inventario de las instancias EC2

![Inventario de las instancias EC2](assets/ec2_instances.png)

> **Nota:** las dos imágenes anteriores son resúmenes generados a partir del
> despliegue real, con los IDs, las IPs y el estado `running` (en ejecución). Si la entrega exige
> capturas de la consola de AWS, añádelas desde `VPC → Your VPCs`, `VPC → Subnets`
> y `EC2 → Instances`.

## Parte C — Despliegue con Terraform

### Estructura del proyecto

```text
pt1-4-ex2/
├── assets/
│   ├── topologia.drawio       # Fuente editable del diagrama (draw.io)
│   ├── topologia.png          # Diagrama de topología
│   ├── vpc_subnets.png        # Resumen de la VPC y las subredes
│   └── ec2_instances.png      # Inventario de las 6 instancias
├── .gitignore                 # Excluye estado, tfvars y claves privadas *.pem
├── .terraform.lock.hcl        # Versiones fijadas del proveedor de AWS
├── README.md
├── main.tf                    # VPC, IGW, RT, subredes, SG, par de claves y 6 EC2
├── variables.tf               # Variables del proyecto
├── outputs.tf                 # IDs, IPs públicas/privadas y resumen
├── labuser.pub                # Clave pública importada por Terraform
└── terraform.tfvars.example   # Ejemplo de valores para terraform.tfvars
```

`labuser.pem` se genera localmente, no se versiona y está excluido por `*.pem` en
`.gitignore`. Terraform solo importa la clave pública `labuser.pub`.

### Configuración principal

`main.tf` declara el proveedor de AWS, la VPC, las subredes, la puerta de enlace de Internet, la
tabla de rutas, el grupo de seguridad, el par de claves y las seis instancias:

```hcl
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

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "pt1-4-ex2-vpc"
    Project = "pt1-4-ex2"
  }
}
```

Las subredes se crean con `for_each` a partir del mapa definido en `variables.tf` y
tienen IP pública automática:

```hcl
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
```

La salida a Internet se resuelve con una puerta de enlace de Internet (IGW) y una tabla de rutas común:

```hcl
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
```

El par de claves se importa desde la clave pública local y el grupo de seguridad solo
permite SSH desde la IP indicada en `ssh_cidr`:

```hcl
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file("${path.module}/labuser.pub")

  tags = {
    Name    = var.key_name
    Project = "pt1-4-ex2"
  }
}

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
}
```

Las seis instancias también se generan con `for_each`, asignando dos a cada subred,
con el par de claves y una IP pública:

```hcl
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
```

### Variables

| Variable | Valor por defecto | Descripción |
|---|---|---|
| `aws_region` | `us-east-1` | Región de AWS |
| `vpc_cidr` | `10.0.0.0/16` | CIDR de la VPC |
| `availability_zone` | `us-east-1a` | AZ común a las subredes |
| `ami_id` | `ami-04b938437b69a2c9c` | AMI de Amazon Linux 2023 |
| `instance_type` | `t3.micro` | Tipo de instancia |
| `key_name` | `labuser` | Nombre del par de claves EC2 |
| `ssh_cidr` | `81.42.248.211/32` | IP autorizada para SSH |
| `subnets` | A/B/C con sus CIDR | Mapa de subredes |

La AMI es la misma que se utiliza en `pt1-4-ex1`. Si el ID deja de estar disponible,
se puede consultar la AMI vigente de Amazon Linux 2023 en `us-east-1` o usar un
`data source`.

### Outputs

`outputs.tf` expone:

- `vpc_id` y `vpc_cidr`.
- `subnet_ids` y `subnet_cidrs`, indexados por `A`, `B` y `C`.
- `security_group_id`.
- `key_name`.
- `internet_gateway_id` y `route_table_id`.
- `instance_ids`, `instance_private_ips` e `instance_public_ips`, indexados por nombre.
- `instance_summary`, con ID, IP privada, IP pública, subred, estado y tipo de cada
  instancia.

## Clave SSH

Si no existe el par de claves, se genera localmente con formato PEM:

```bash
ssh-keygen -t rsa -b 2048 -m PEM -f labuser.pem -N ""
mv labuser.pem.pub labuser.pub
chmod 400 labuser.pem
```

Terraform importa únicamente `labuser.pub` en AWS con el nombre `labuser`. La clave
privada `labuser.pem` nunca se sube al repositorio ni se guarda en el estado de
Terraform.

## Despliegue

### Requisitos

- Terraform `>= 1.3.0`.
- Credenciales de AWS configuradas en `~/.aws/credentials` (no se versionan).
- Permisos para VPC, subredes, puertas de enlace de Internet, tablas de rutas, grupos de seguridad,
  pares de claves y EC2.
- `labuser.pem` y `labuser.pub` (ver la sección **Clave SSH**).

Desde la carpeta del ejercicio:

```bash
cd practiquescloud/pt1-4-ex2

# 1. Descarga el proveedor y crea el archivo de bloqueo
terraform init

# 2. Comprueba formato y sintaxis
terraform fmt -check
terraform validate

# 3. Revisa el plan
terraform plan -out=tfplan

# 4. Crea la VPC, el IGW, la tabla de rutas, el SG, el par de claves y las 6 instancias
terraform apply tfplan
```

Si se quiere personalizar algún valor:

```bash
cp terraform.tfvars.example terraform.tfvars
# editar terraform.tfvars, por ejemplo ssh_cidr con la IP actual
terraform plan -out=tfplan
terraform apply tfplan
```

Al finalizar, consulta los resultados:

```bash
terraform output
terraform output instance_summary
terraform output instance_private_ips
terraform output instance_public_ips
```

## Resultados del despliegue

Recursos principales creados:

| Recurso | Nombre | ID |
|---|---|---|
| VPC | `pt1-4-ex2-vpc` | `vpc-06450dfe9b672fb76` |
| Puerta de enlace de Internet (IGW) | `pt1-4-ex2-igw` | `igw-0edf154177220693f` |
| Tabla de rutas | `pt1-4-ex2-rt-public` | `rtb-03f15c1eb55b7869d` |
| Grupo de seguridad | `pt1-4-ex2-sg` | `sg-02a8dd559af3a803e` |
| Par de claves | `labuser` | — |

Subredes:

| Subred | CIDR | ID |
|---|---|---|
| A | `10.0.32.0/25` | `subnet-0a8b32e27b1802f54` |
| B | `10.0.30.0/23` | `subnet-02a25427e2d999a4b` |
| C | `10.0.33.0/28` | `subnet-0659d5cfcbe04ec65` |

Instancias:

| Nombre | ID | Subred | IP privada | IP pública | Estado |
|---|---|---|---|---|---|
| `ec2-a-1` | `i-0d20509c9c5155cc5` | A | `10.0.32.85` | `3.85.47.248` | `running` |
| `ec2-a-2` | `i-08bebbc665f435b45` | A | `10.0.32.126` | `44.204.238.142` | `running` |
| `ec2-b-1` | `i-09d46c69597596c46` | B | `10.0.30.61` | `18.212.173.129` | `running` |
| `ec2-b-2` | `i-08f5e26d183a4f53b` | B | `10.0.31.115` | `44.203.0.121` | `running` |
| `ec2-c-1` | `i-0850a7e2f34822b07` | C | `10.0.33.9` | `52.91.239.228` | `running` |
| `ec2-c-2` | `i-0eb479b3033ca900d` | C | `10.0.33.14` | `54.165.108.30` | `running` |

> Las IPs públicas son las del despliegue actual. Si se destruyen y se vuelven a
> crear las instancias, AWS asignará otras.

## Acceso SSH

El grupo de seguridad solo permite el puerto 22 desde `ssh_cidr`
(`81.42.248.211/32` por defecto). Si tu IP pública cambia, actualiza `ssh_cidr` en
`terraform.tfvars` o en `variables.tf` y vuelve a aplicar.

```bash
# Copia la clave a un directorio con permisos restrictivos
cp labuser.pem ~/.ssh/labuser.pem
chmod 600 ~/.ssh/labuser.pem

# Conexión a una instancia
ssh -i ~/.ssh/labuser.pem ec2-user@3.85.47.248
```

También se pueden probar las seis instancias:

```bash
for ip in 3.85.47.248 44.204.238.142 18.212.173.129 \
          44.203.0.121 52.91.239.228 54.165.108.30; do
  echo "== $ip =="
  ssh -i ~/.ssh/labuser.pem -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
      ec2-user@"$ip" 'hostname; hostname -I'
done
```

En WSL, si el archivo del proyecto está en `/mnt/c`, los permisos pueden mostrarse
como demasiado abiertos. Usa la copia en `~/.ssh/labuser.pem` o ejecuta `chmod 400`
sobre una copia en el sistema de archivos de Linux.

## Verificación

Con Terraform:

```bash
terraform state list
terraform show
```

Con AWS CLI:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Project,Values=pt1-4-ex2" \
  --query "Reservations[].Instances[].{Nombre:Tags[?Key=='Name']|[0].Value,ID:InstanceId,Estado:State.Name,Tipo:InstanceType,Subred:SubnetId,IPPrivada:PrivateIpAddress,IPPublica:PublicIpAddress}" \
  --output table
```

También se pueden consultar en la consola:

- **VPC → Your VPCs** para ver `pt1-4-ex2-vpc`.
- **VPC → Subnets** para ver las tres subredes.
- **VPC → Internet gateways** y **Route tables** para ver la salida a Internet.
- **EC2 → Instances** filtrando por `Project = pt1-4-ex2` para ver las seis instancias.

Las seis instancias se han comprobado por SSH con `labuser.pem`; todas responden como
`ec2-user` con Amazon Linux 2023 y estado `running` (en ejecución).

## Limpieza de recursos

Para evitar cargos, destruye toda la infraestructura cuando termines:

```bash
terraform plan -destroy
terraform destroy
```

Confirma la destrucción escribiendo `yes`. El `destroy` elimina las seis instancias,
el par de claves, el grupo de seguridad, la puerta de enlace de Internet, la tabla de rutas, las
subredes y la VPC. El archivo local `labuser.pem` no se elimina.

## Comparación: consola vs. Terraform

| Aspecto | Consola de AWS | Terraform |
|---|---|---|
| Velocidad inicial | Rápida para pocos recursos | Requiere escribir el código |
| Reproducibilidad | Manual, depende de los pasos | Alta, el código se repite |
| Errores humanos | Fáciles de cometer | Menores, validados con `plan` |
| Versionado | No | Sí, en Git |
| Cambios | Manuales | `terraform plan` + `apply` |
| Documentación | Capturas de pantalla | Código y README |
| Eliminación | Manual, recurso a recurso | `terraform destroy` |

## Decisiones técnicas y limitaciones

- **Misma AZ:** las tres subredes están en `us-east-1a` para cumplir el enunciado.
- **Subredes públicas:** se crea una puerta de enlace de Internet (IGW) y una tabla de rutas pública con
  `0.0.0.0/0 → IGW`. Las instancias tienen IP pública y salida directa a Internet.
  No se usa NAT Gateway porque no hay subredes privadas.
- **Acceso SSH:** el grupo de seguridad solo permite el puerto 22 desde `ssh_cidr`
  (`81.42.248.211/32` por defecto). El resto del tráfico de entrada queda bloqueado.
- **Par de claves:** Terraform importa `labuser.pub` como `labuser`; la clave privada
  `labuser.pem` se genera localmente y está excluida por `.gitignore`.
- **AMI fijada:** el ID `ami-04b938437b69a2c9c` corresponde a una AMI de Amazon Linux
  2023 de `us-east-1`. Las AMI se actualizan y el ID puede quedar obsoleto. Si
  `terraform plan` devuelve `InvalidAMIID.NotFound`, hay que consultar la AMI vigente
  o usar un `data source`.
- **Estado local:** se utiliza `terraform.tfstate` local. No debe versionarse. Para un
  entorno de equipo se recomienda un backend remoto, como S3 con bloqueo en DynamoDB.
- **Coste:** seis instancias `t3.micro` encendidas 24/7 y sus IPs públicas pueden
  superar el nivel gratuito. Hay que ejecutar `terraform destroy` al terminar.
- **IPs públicas:** las IPs asignadas pueden cambiar si las instancias se recrean.

## Mejoras opcionales

- Añadir un **NAT Gateway** si se quieren subredes privadas con salida a Internet.
- Usar **AWS Systems Manager** en lugar de SSH, con un rol de IAM y el agente SSM.
- Convertir la infraestructura en **módulos** reutilizables.
- Añadir **validaciones de CIDR** en las variables.
- Usar un **backend remoto** para el estado de Terraform.
- Añadir un **Application Load Balancer** y un Auto Scaling Group como siguiente paso.
- Reservar **Elastic IPs** si se necesita una IP pública fija.
- Añadir un **bastion host** o limitar aún más el acceso SSH.

## Autor

- **Moha591** — [github.com/Moha591](https://github.com/Moha591)
- Repositorio: [github.com/Moha591/practiquescloud](https://github.com/Moha591/practiquescloud)
