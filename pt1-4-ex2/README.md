# Ejercicio 2 — Diseño y despliegue de VPC, subredes y EC2

## Objetivo

Comprender la segmentación de redes en AWS mediante una VPC con tres subredes y
comparar dos formas de despliegue:

- **Parte B:** despliegue manual desde la consola de AWS.
- **Parte C:** despliegue automatizado con Terraform.

Las tres subredes se encuentran en la misma zona de disponibilidad (`us-east-1a`) y
en cada una se despliegan dos instancias EC2 `t3.micro` con Amazon Linux 2023, hasta
un total de **6 instancias**.

El diseño es de subredes privadas: no se asigna IP pública a las instancias y no se
declara Internet Gateway ni tabla de rutas hacia Internet.

## Diseño de red

| Subred | CIDR | Zona | Instancias |
|---|---|---|---|
| Subred A | `10.0.32.0/25` | `us-east-1a` | 2 |
| Subred B | `10.0.30.0/23` | `us-east-1a` | 2 |
| Subred C | `10.0.33.0/28` | `us-east-1a` | 2 |
| **Total** | **VPC `10.0.0.0/16`** | | **6** |

Los rangos no se solapan:

- Subred A: `10.0.32.0` — `10.0.32.127`
- Subred B: `10.0.30.0` — `10.0.31.255`
- Subred C: `10.0.33.0` — `10.0.33.15`

Todas las subredes pertenecen a la VPC `10.0.0.0/16` y están en `us-east-1a`.

## Topología

![Topología de la VPC y las subredes](assets/topologia.png)

El diagrama editable se encuentra en
[`assets/topologia.drawio`](assets/topologia.drawio) y se ha exportado a
[`assets/topologia.png`](assets/topologia.png).

## Parte A — Diseño de la red

La infraestructura se ha diseñado con estos criterios:

- Una VPC principal con bloque `10.0.0.0/16`.
- Tres subredes de tamaños diferentes para practicar el cálculo de CIDR.
- Las tres subredes en la misma zona de disponibilidad (`us-east-1a`).
- Dos instancias EC2 por subred, con un total de seis.
- Sin solapamientos entre subredes.
- Sin IP pública en las instancias.
- Sin Internet Gateway ni tabla de rutas pública.
- Sin reglas de entrada SSH.

## Parte B — Despliegue manual en la consola de AWS

El despliegue manual se realiza **íntegramente desde la consola de AWS**, sin
utilizar la terminal. Los pasos son:

1. **Crear la VPC**
   - Ir a **VPC → Your VPCs → Create VPC**.
   - Nombre: `pt1-4-ex2-vpc`.
   - Bloque IPv4 CIDR: `10.0.0.0/16`.
   - Sin subredes automáticas, sin Internet Gateway.
   - Pulsar **Create VPC**.

2. **Crear las subredes**
   - Ir a **VPC → Subnets → Create subnet**.
   - Seleccionar la VPC `pt1-4-ex2-vpc`.
   - Crear tres subredes, todas en la zona `us-east-1a`:
     - `pt1-4-ex2-subnet-a` → `10.0.32.0/25`
     - `pt1-4-ex2-subnet-b` → `10.0.30.0/23`
     - `pt1-4-ex2-subnet-c` → `10.0.33.0/28`
   - En **Actions → Modify auto-assign IP settings** de cada subred, dejar
     **Auto-assign public IPv4 = Disable** (son subredes privadas).

3. **Lanzar las instancias EC2**
   - Ir a **EC2 → Instances → Launch instances**.
   - Nombre: `a1` (y repetir con `a2`, `b1`, `b2`, `c1`, `c2`).
   - AMI: **Amazon Linux 2023 (x86_64)**.
   - Tipo de instancia: `t3.micro`.
   - En **Network settings**, seleccionar la VPC `pt1-4-ex2-vpc` y la subred
     correspondiente (`pt1-4-ex2-subnet-a`, `b` o `c`).
   - **No** marcar la opción de asignar IP pública (no hay `subnet_id` con IP
     pública automática).
   - Pulsar **Launch instance** y repetir hasta tener 6 instancias, dos por subred.

4. **Comprobar el estado**
   - En **EC2 → Instances**, verificar que las seis instancias están en estado
     `Running`, con IP privada dentro del rango de su subred y **sin IP pública**.

5. **Comprobar la red**
   - En **VPC → Your VPCs** aparece `pt1-4-ex2-vpc` con CIDR `10.0.0.0/16`.
   - En **VPC → Subnets** aparecen las tres subredes con los CIDR indicados y
     `Auto-assign public IPv4 = Disable`.

> En la consola de AWS no se crean recursos por terminal. Los pasos anteriores
> describen únicamente acciones de la interfaz web de AWS.

### Capturas del despliegue manual

![Resumen de la VPC y las subredes](assets/vpc_subnets.png)

![Inventario de las instancias EC2](assets/ec2_instances.png)

## Parte C — Despliegue con Terraform

### Estructura del proyecto

```text
pt1-4-ex2/
├── assets/
│   ├── topologia.drawio
│   ├── topologia.png
│   ├── vpc_subnets.png
│   └── ec2_instances.png
├── main.tf
└── README.md
```

### Código Terraform

`main.tf` declara explícitamente la VPC, las tres subredes y las seis instancias.
Cada instancia tiene asignada su subred mediante `subnet_id`.

```hcl
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.32.0/25"
  availability_zone = "us-east-1a"
}

resource "aws_instance" "a1" {
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.a.id
}
```

El resto de subredes e instancias siguen el mismo patrón:

| Instancia | Subred asignada |
|---|---|
| `a1`, `a2` | Subred A |
| `b1`, `b2` | Subred B |
| `c1`, `c2` | Subred C |

El enunciado menciona `main.tf`, `variables.tf`, etc. En esta entrega se ha mantenido
un único `main.tf` con valores explícitos, sin variables ni outputs, para respetar el
alcance mínimo solicitado.

### Despliegue

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

## Resultados del despliegue Terraform

Infraestructura desplegada y verificada en `us-east-1`.

| Recurso | ID |
|---|---|
| VPC | `vpc-0bddadd7f1bbffc4a` |

Subredes:

| Subred | CIDR | ID |
|---|---|---|
| A | `10.0.32.0/25` | `subnet-0483cccb507b97227` |
| B | `10.0.30.0/23` | `subnet-0262e3512fb34f972` |
| C | `10.0.33.0/28` | `subnet-0dbcb961d246c4b5b` |

Instancias:

| Instancia | Subred | ID | IP privada | IP pública | Estado |
|---|---|---|---|---|---|
| `a1` | A | `i-0ab9af89cad710b83` | `10.0.32.37` | — | `running` |
| `a2` | A | `i-019078f463905170c` | `10.0.32.74` | — | `running` |
| `b1` | B | `i-0721fd1675cafa8eb` | `10.0.31.65` | — | `running` |
| `b2` | B | `i-0b2b9f3a2a9a1e593` | `10.0.30.113` | — | `running` |
| `c1` | C | `i-0dba10fa401739e69` | `10.0.33.5` | — | `running` |
| `c2` | C | `i-097fa8b27d86cfc00` | `10.0.33.10` | — | `running` |

Comprobaciones realizadas:

- `terraform validate` correcto.
- `terraform apply` completado: **10 recursos creados**.
- `terraform plan` posterior: **sin cambios** (infraestructura idempotente).
- Las 6 instancias en `running` y con los chequeos `2/2` en `ok`.
- Ninguna instancia tiene IP pública.
- Las 6 instancias usan `t3.micro` y la AMI `ami-04b938437b69a2c9c`.

## Verificación

Desde la consola de AWS:

- **VPC → Your VPCs** para ver `vpc-0bddadd7f1bbffc4a` con CIDR `10.0.0.0/16`.
- **VPC → Subnets** para ver las tres subredes con sus CIDR y
  `Auto-assign public IPv4 = Disable`.
- **EC2 → Instances** para ver las seis instancias en estado `running`, cada una en
  su subred y sin IP pública.

Desde la terminal, la comprobación se puede repetir con AWS CLI:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=vpc-id,Values=vpc-0bddadd7f1bbffc4a" \
  --query "Reservations[].Instances[].{ID:InstanceId,Estado:State.Name,Tipo:InstanceType,Subred:SubnetId,IPPrivada:PrivateIpAddress,IPPublica:PublicIpAddress}" \
  --output table
```

## Comparación: consola vs. Terraform

| Aspecto | Consola de AWS | Terraform |
|---|---|---|
| Velocidad inicial | Rápida para pocos recursos | Requiere escribir el código |
| Reproducibilidad | Manual, depende de los pasos | Alta, el código se repite |
| Errores humanos | Fáciles de cometer | Menores, validados con `plan` |
| Versionado | No | Sí, en Git |
| Cambios | Manuales | `terraform plan` + `apply` |
| Eliminación | Manual, recurso a recurso | `terraform destroy` |

## Limpieza de recursos

Para evitar cargos, se puede destruir toda la infraestructura:

```bash
terraform plan -destroy
terraform destroy
```

El `destroy` elimina las seis instancias, las subredes y la VPC.

## Decisiones y limitaciones

- **Misma AZ:** las tres subredes están en `us-east-1a` para cumplir el enunciado.
- **Subredes privadas:** no se declara Internet Gateway ni tabla de rutas pública.
  Las instancias no tienen IP pública.
- **Alcance mínimo:** Terraform crea únicamente la VPC, las tres subredes y las seis
  instancias. No se declaran Security Groups, key pairs, variables ni outputs.
- **AMI fijada:** el ID `ami-04b938437b69a2c9c` corresponde a una AMI de Amazon Linux
  2023 de `us-east-1`. Si deja de estar disponible, hay que actualizar el ID.
- **Estado local:** se utiliza `terraform.tfstate` local. No debe versionarse.
- **Coste:** seis instancias `t3.micro` encendidas 24/7 pueden superar el nivel
  gratuito. Hay que ejecutar `terraform destroy` al terminar.
- **IPs privadas:** las IPs asignadas pueden cambiar si las instancias se recrean.

## Conclusión

El despliegue manual permite entender la creación de cada recurso desde la consola,
mientras que Terraform permite reproducir la misma infraestructura de forma más
rápida y controlada. La VPC queda segmentada en tres subredes dentro de la misma zona
de disponibilidad, con dos instancias EC2 en cada una y sin exposición pública.