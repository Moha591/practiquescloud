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

## Parte B — Despliegue manual por consola de AWS

El despliegue manual se realizó desde la consola de AWS siguiendo estos pasos:

1. **Crear la VPC:** `VPC → Your VPCs → Create VPC`, con nombre `pt1-4-ex2-vpc`,
   CIDR `10.0.0.0/16` y sin subredes automáticas.
2. **Crear las subredes:** `VPC → Subnets → Create subnet`, seleccionando la VPC
   anterior, la zona `us-east-1a` y los CIDR `10.0.32.0/25`, `10.0.30.0/23` y
   `10.0.33.0/28`.
3. **Lanzar las instancias:** `EC2 → Instances → Launch instances`, con Amazon Linux
   2023, tipo `t3.micro` y la subred correspondiente. Se crearon dos instancias por
   subred, hasta un total de seis.
4. **Comprobar el estado:** se verificó en `EC2 → Instances` que las seis instancias
   estaban en estado `running`, con IP privada y sin IP pública.
5. **Tomar las capturas:** se capturaron la VPC, las subredes y el listado final de
   las seis instancias.

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
terraform plan
terraform apply
```

## Resultados del despliegue

Recursos principales:

| Recurso | Nombre | ID |
|---|---|---|
| VPC | `pt1-4-ex2-vpc` | `vpc-06450dfe9b672fb76` |

Subredes:

| Subred | CIDR | ID |
|---|---|---|
| A | `10.0.32.0/25` | `subnet-0a8b32e27b1802f54` |
| B | `10.0.30.0/23` | `subnet-02a25427e2d999a4b` |
| C | `10.0.33.0/28` | `subnet-0659d5cfcbe04ec65` |

Instancias:

| Instancia | Subred | ID | IP privada | Estado |
|---|---|---|---|---|
| `a1` | A | `i-0fb1ef955e7b5858a` | `10.0.32.63` | `running` |
| `a2` | A | `i-01c34a89f18db89ea` | `10.0.32.21` | `running` |
| `b1` | B | `i-000293bd511e02f15` | `10.0.30.240` | `running` |
| `b2` | B | `i-0e81ce1aa3ee1e300` | `10.0.30.246` | `running` |
| `c1` | C | `i-0f97d673995663e0d` | `10.0.33.6` | `running` |
| `c2` | C | `i-0a5f3bc7c970f32b0` | `10.0.33.5` | `running` |

> Los IDs y las IPs corresponden a la ejecución documentada. Pueden cambiar si la
> infraestructura se recrea.

## Verificación

Se comprobó que las seis instancias estaban en ejecución y que ninguna tenía IP
pública. La comprobación se puede repetir con AWS CLI:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].{ID:InstanceId,Estado:State.Name,Tipo:InstanceType,Subred:SubnetId,IPPrivada:PrivateIpAddress,IPPublica:PublicIpAddress}" \
  --output table
```

Resultado esperado: seis instancias en estado `running`, con IP privada y sin IP
pública.

También se puede comprobar desde la consola:

- **VPC → Your VPCs** para ver `pt1-4-ex2-vpc`.
- **VPC → Subnets** para ver las tres subredes.
- **EC2 → Instances** para ver las seis instancias en ejecución.

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
