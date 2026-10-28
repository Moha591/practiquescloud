# Ejercicio 2 — Diseño y despliegue de VPC, subredes y EC2 (Consola + IaC)

## Objetivo

Comprender la segmentación de redes en AWS mediante una VPC con tres subredes y
comparar dos formas de despliegue:

- **Parte B:** despliegue manual desde la consola de AWS.
- **Parte C:** despliegue automatizado con Terraform (IaC).

Las tres subredes se encuentran en la misma zona de disponibilidad (`us-east-1a`) y
en cada una se despliegan dos instancias EC2 `t3.micro` con Amazon Linux 2023, hasta
un total de **6 instancias**.

El diseño es de **subredes privadas**: no hay Internet Gateway, tabla de rutas
pública, NAT Gateway ni IPs públicas. El grupo de seguridad no tiene reglas de
entrada, por lo que las instancias no son accesibles desde Internet.

Se mantiene el par de claves `labuser` y el archivo local `labuser.pem`, pero el
diseño actual no permite SSH desde Internet. La clave queda preparada para futuras
prácticas en las que se añada acceso público, un bastion host o AWS Systems Manager.

## Diseño de red

| Subred | CIDR | Zona | Tipo | Direcciones | Usables | Instancias |
|---|---|---|---|---|---|---|
| Subred A | `10.0.32.0/25` | `us-east-1a` | Privada | 128 | 123 | 2 |
| Subred B | `10.0.30.0/23` | `us-east-1a` | Privada | 512 | 507 | 2 |
| Subred C | `10.0.33.0/28` | `us-east-1a` | Privada | 16 | 11 | 2 |
| **Total** | **VPC `10.0.0.0/16`** | | | | | **6** |

AWS reserva 5 direcciones en cada subred (red, router, DNS, futuras y broadcast), por
eso el número de direcciones usables es el total menos cinco.

Los rangos no se solapan:

- Subred A: `10.0.32.0` — `10.0.32.127`
- Subred B: `10.0.30.0` — `10.0.31.255`
- Subred C: `10.0.33.0` — `10.0.33.15`

Todos los rangos pertenecen a la VPC `10.0.0.0/16`.

Las tres subredes son privadas: `map_public_ip_on_launch = false`, no están asociadas
a ninguna tabla de rutas con salida a Internet y las instancias no tienen IP pública.

## Topología

![Topología de la VPC y las subredes](assets/topologia.png)

La VPC contiene una única zona de disponibilidad (`us-east-1a`) con las tres subredes
privadas. Cada subred aloja dos instancias EC2. Todas comparten el grupo de seguridad
`pt1-4-ex2-sg`, que no tiene reglas de entrada, y el par de claves `labuser`.

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
- Subredes privadas, sin Internet Gateway ni tabla de rutas pública.
- Sin IP pública en las instancias.
- Grupo de seguridad común sin reglas de entrada.
- Par de claves `labuser` asociado a las instancias.
- Etiquetas `Project = pt1-4-ex2` para localizar todos los recursos.

## Parte B — Despliegue por consola de AWS

El despliegue manual se realiza desde la consola de AWS con estos pasos:

1. **Crear la VPC:** `VPC → Your VPCs → Create VPC`, seleccionando solo la VPC
   (sin subredes automáticas), con nombre `pt1-4-ex2-vpc` y CIDR `10.0.0.0/16`.
   Activar el soporte DNS y los nombres de host DNS.
2. **Crear las subredes:** `VPC → Subnets → Create subnet`, seleccionando la VPC
   anterior, la AZ `us-east-1a` y los CIDR `10.0.32.0/25`, `10.0.30.0/23` y
   `10.0.33.0/28`. No activar la asignación automática de IP pública.
3. **Crear el grupo de seguridad:** `EC2 → Security groups → Create security group`
   en la VPC, sin reglas de entrada y con salida permitida. Las instancias no serán
   accesibles desde Internet.
4. **Crear el par de claves:** `EC2 → Key pairs → Create key pair`, tipo RSA, formato
   `.pem`, nombre `labuser`. Descargar `labuser.pem` y guardarlo en un lugar seguro.
5. **Crear las instancias:** `EC2 → Instances → Launch instances`, con Amazon Linux
   2023, tipo `t3.micro`, la VPC y la subred correspondiente. Se crean dos instancias
   por subred, con el par de claves `labuser`, el grupo de seguridad del ejercicio y
   sin IP pública.
6. **Etiquetar los recursos** con `Project = pt1-4-ex2` para poder filtrarlos.
7. **Tomar las capturas** de la VPC, las subredes y el listado de las seis instancias.

### Resumen de la VPC y las subredes

![Resumen de la VPC y las subredes](assets/vpc_subnets.png)

### Inventario de las instancias EC2

![Inventario de las instancias EC2](assets/ec2_instances.png)

> **Nota:** las dos imágenes anteriores son resúmenes generados a partir del
> despliegue real, con los IDs, las IPs privadas y el estado `running`. Si la entrega
> exige capturas de la consola de AWS, añádelas desde `VPC → Your VPCs`,
> `VPC → Subnets` y `EC2 → Instances`.

## Parte C — Despliegue con Terraform

### Estructura del proyecto

```text
pt1-4-ex2/
├── assets/
│   ├── topologia.drawio       # Fuente editable del diagrama (draw.io)
│   ├── topologia.png          # Diagrama de topología privada
│   ├── vpc_subnets.png        # Resumen de la VPC y las subredes
│   └── ec2_instances.png      # Inventario de las 6 instancias
├── .gitignore                 # Excluye estado, tfvars y claves privadas *.pem
├── .terraform.lock.hcl        # Versiones fijadas del proveedor de AWS
├── README.md
├── main.tf                    # VPC, subredes, SG, key pair y 6 EC2
├── variables.tf               # Variables del proyecto
├── outputs.tf                 # IDs, IPs privadas y resumen
├── labuser.pub                # Clave pública importada por Terraform
└── terraform.tfvars.example   # Ejemplo de valores para terraform.tfvars
```

`labuser.pem` se genera localmente, no se versiona y está excluido por `*.pem` en
`.gitignore`. Terraform solo importa la clave pública `labuser.pub`.

### Configuración principal

`main.tf` declara el proveedor de AWS, la VPC, las subredes privadas, el grupo de
seguridad, el par de claves y las seis instancias:

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
no asignan IP pública:

```hcl
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
```

El par de claves se importa desde la clave pública local:

```hcl
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file("${path.module}/labuser.pub")

  tags = {
    Name    = var.key_name
    Project = "pt1-4-ex2"
  }
}
```

El grupo de seguridad no tiene reglas de entrada:

```hcl
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
```

Las seis instancias también se generan con `for_each`, asignando dos a cada subred,
con el par de claves y sin IP pública:

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
  associate_public_ip_address = false

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
- `instance_ids` e `instance_private_ips`, indexados por nombre.
- `instance_summary`, con ID, IP privada, subred, estado y tipo de cada instancia.

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

> **Importante:** en este diseño las subredes son privadas y el grupo de seguridad no
> tiene reglas de entrada. Tener `labuser.pem` no permite conectarse por SSH desde
> Internet. La clave queda preparada para cuando se añada un Internet Gateway, una IP
> pública, un bastion host o AWS Systems Manager.

## Despliegue

### Requisitos

- Terraform `>= 1.3.0`.
- Credenciales de AWS configuradas en `~/.aws/credentials` (no se versionan).
- Permisos para VPC, subredes, grupos de seguridad, pares de claves y EC2.
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

# 4. Crea la VPC, las subredes, el grupo de seguridad, el par de claves y las 6 instancias
terraform apply tfplan
```

Si se quiere personalizar algún valor:

```bash
cp terraform.tfvars.example terraform.tfvars
# editar terraform.tfvars
terraform plan -out=tfplan
terraform apply tfplan
```

Al finalizar, consulta los resultados:

```bash
terraform output
terraform output instance_summary
terraform output instance_private_ips
```

## Resultados del despliegue

Recursos principales creados:

| Recurso | Nombre | ID |
|---|---|---|
| VPC | `pt1-4-ex2-vpc` | `vpc-06450dfe9b672fb76` |
| Grupo de seguridad | `pt1-4-ex2-sg` | `sg-0532dbe814f80f6fa` |
| Par de claves | `labuser` | — |

Subredes:

| Subred | CIDR | ID |
|---|---|---|
| A | `10.0.32.0/25` | `subnet-0a8b32e27b1802f54` |
| B | `10.0.30.0/23` | `subnet-02a25427e2d999a4b` |
| C | `10.0.33.0/28` | `subnet-0659d5cfcbe04ec65` |

Instancias:

| Nombre | ID | Subred | IP privada | Estado |
|---|---|---|---|---|
| `ec2-a-1` | `i-0fb1ef955e7b5858a` | A | `10.0.32.63` | `running` |
| `ec2-a-2` | `i-01c34a89f18db89ea` | A | `10.0.32.21` | `running` |
| `ec2-b-1` | `i-000293bd511e02f15` | B | `10.0.30.240` | `running` |
| `ec2-b-2` | `i-0e81ce1aa3ee1e300` | B | `10.0.30.246` | `running` |
| `ec2-c-1` | `i-0f97d673995663e0d` | C | `10.0.33.6` | `running` |
| `ec2-c-2` | `i-0a5f3bc7c970f32b0` | C | `10.0.33.5` | `running` |

> Las instancias no tienen IP pública. Las IPs privadas son las del despliegue
> actual y pueden cambiar si las instancias se recrean.

## Acceso y limitaciones

No hay acceso SSH desde Internet en este diseño:

- Las subredes son privadas y no tienen ruta a un Internet Gateway.
- Las instancias no tienen IP pública.
- El grupo de seguridad `pt1-4-ex2-sg` no tiene reglas de entrada.

El par de claves `labuser` está asociado a las instancias y `labuser.pem` está
disponible en local, pero no se puede usar para conectarse desde fuera de la VPC. Para
habilitar el acceso habría que añadir una de estas opciones:

- Un **Internet Gateway**, una tabla de rutas pública y IPs públicas, con una regla
  SSH restringida a una IP concreta.
- Un **bastion host** en una subred pública.
- **AWS Systems Manager Session Manager**, que no requiere abrir el puerto 22.

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

La columna `IPPublica` debe aparecer vacía o como `None` para las seis instancias.

También se pueden consultar en la consola:

- **VPC → Your VPCs** para ver `pt1-4-ex2-vpc`.
- **VPC → Subnets** para ver las tres subredes privadas.
- **EC2 → Instances** filtrando por `Project = pt1-4-ex2` para ver las seis instancias.

## Limpieza de recursos

Para evitar cargos, destruye toda la infraestructura cuando termines:

```bash
terraform plan -destroy
terraform destroy
```

Confirma la destrucción escribiendo `yes`. El `destroy` elimina las seis instancias,
el par de claves, el grupo de seguridad, las subredes y la VPC. El archivo local
`labuser.pem` no se elimina.

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
- **Subredes privadas:** no se crea Internet Gateway, tabla de rutas pública ni NAT.
  Las instancias no tienen IP pública y no tienen salida directa a Internet.
- **Grupo de seguridad:** se crea `pt1-4-ex2-sg` con salida permitida y sin reglas de
  entrada. Las instancias no son accesibles desde Internet.
- **Par de claves:** Terraform importa `labuser.pub` como `labuser`; la clave privada
  `labuser.pem` se genera localmente y está excluida por `.gitignore`. La clave está
  asociada, pero no hay camino de red para SSH desde Internet.
- **AMI fijada:** el ID `ami-04b938437b69a2c9c` corresponde a una AMI de Amazon Linux
  2023 de `us-east-1`. Las AMI se actualizan y el ID puede quedar obsoleto. Si
  `terraform plan` devuelve `InvalidAMIID.NotFound`, hay que consultar la AMI vigente
  o usar un `data source`.
- **Estado local:** se utiliza `terraform.tfstate` local. No debe versionarse. Para un
  entorno de equipo se recomienda un backend remoto, como S3 con bloqueo en DynamoDB.
- **Coste:** seis instancias `t3.micro` encendidas 24/7 pueden superar el nivel
  gratuito. Hay que ejecutar `terraform destroy` al terminar.
- **IPs privadas:** las IPs asignadas pueden cambiar si las instancias se recrean.

## Mejoras opcionales

- Añadir un **Internet Gateway**, una tabla de rutas pública e IPs públicas para
  habilitar SSH, con una regla restringida a una IP concreta.
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
