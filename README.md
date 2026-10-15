# FreshBox SpA — Arquitectura Cloud EA2 (EKS + RDS Multi-AZ)

**Experiencia de Aprendizaje 2 (EA2) | Evaluación Parcial 2 | ARY1102 Arquitectura Cloud | DuocUC 2026**  
**Autor:** Gaston Mardones González  
**Docente Diseñador:** Ignacio A. Pastenet M.

---

## 1. Descripción del Proyecto y Evolución Arquitectónica

En la **Fase 1 (EA1)**, FreshBox SpA implementó un catálogo online de productos orgánicos sobre una arquitectura base utilizando contenedores Docker / ECS Fargate y una base de datos relacional MySQL alojada en una instancia EC2 con respaldos automáticos en AWS Backup.

Para esta **Fase 2 (EA2)**, en respuesta a la expansión sostenida del negocio y la necesidad de una plataforma de nivel empresarial sin sobrecarga operativa, la arquitectura evoluciona hacia:
1. **Orquestación Cloud-Native con Amazon EKS (Elastic Kubernetes Service):** Reemplazando la gestión de tareas por un clúster Kubernetes administrado con un **Managed Node Group Multi-AZ** (2 a 4 nodos trabajadores en subredes privadas), autoescalado dinámico a nivel de pods (**Horizontal Pod Autoscaler - HPA** al 70% CPU) y balanceo elástico mediante **Application Load Balancer (ALB) Ingress Controller**.
2. **Plataforma de Datos Gestionada (PaaS) con Amazon RDS MySQL Multi-AZ:** Reemplazando el servidor EC2 autogestionado por una base de datos relacional PaaS con replicación sincrónica automática entre Zonas de Disponibilidad (AZ1a y AZ1b), failover transparente en segundos (RTO < 60s, RPO = 0) y respaldos automatizados.
3. **Observabilidad Integral:** Monitoreo métrico granular por pod y nodo a través de **Amazon CloudWatch Container Insights**.

---

## 2. Comparativa Arquitectónica: AS-IS (EA1) vs TO-BE (EA2)

| Criterio | Arquitectura EA1 (EC2 / ECS Fargate) | Arquitectura EA2 (EKS + RDS Multi-AZ) | Ventaja de la Solución EA2 |
| :--- | :--- | :--- | :--- |
| **Orquestador** | ECS Task / Docker manual | **Amazon EKS (Kubernetes 1.30)** | Ecosistema estándar de la industria, portabilidad multi-cloud y control granular de pods. |
| **Escalamiento** | Escalamiento de instancias / tareas | **HPA (Horizontal Pod Autoscaler)** + Cluster Autoscaling | Escala microservicios de manera independiente en segundos al superar el 70% de CPU. |
| **Recuperación ante Fallas** | Reinicio manual de contenedor | **Autorreparación nativa (Self-healing)** | Kubernetes recrea pods fallidos automáticamente según el estado deseado. |
| **Base de Datos** | EC2 MySQL autogestionado | **Amazon RDS MySQL 8.0 Multi-AZ** | Respaldo y mantenimiento sin downtime, failover automático en minutos ante falla de AZ. |
| **Disponibilidad BD** | AWS Backup (RTO de horas) | **Standby Sincrónico Multi-AZ (RTO < 60s, RPO = 0)** | Cero pérdida de transacciones y alta disponibilidad continua 99.95%. |
| **Ingreso y Ruteo** | ALB estático provisionado en IaC | **ALB Ingress dinámico (AWS LB Controller)** | Enrutamiento por rutas `/api/products` y `/` autoconfigurado desde manifiestos K8s. |
| **Observabilidad** | CloudWatch Metrics estándar | **CloudWatch Container Insights** | Visibilidad a nivel de clúster, namespace, pod, nodo y volumen de red. |
| **Carga Operativa** | Alta (parcheo de SO en BD y containers) | **Mínima (Responsabilidad delegada en AWS PaaS)** | El equipo TI se enfoca en desarrollo de funcionalidades comerciales. |

---

## 3. Diagrama de Arquitectura TO-BE (EKS + RDS Multi-AZ)

```mermaid
graph TD
    User[Usuarios / Clientes Web] -->|HTTP / HTTPS| IGW[Internet Gateway]
    IGW --> ALB[Application Load Balancer\nALB Ingress - Subredes Públicas Multi-AZ]

    subgraph VPC_FreshBox ["Amazon VPC FreshBox SpA (10.0.0.0/22)"]
        ALB -->|Ruta / | Svc_Front[Service: frontend :80\nClusterIP]
        ALB -->|Ruta /api/products| Svc_Get[Service: get-products :3001\nClusterIP]

        subgraph Subredes_Publicas ["Subredes Públicas (10.0.0.0/25, 10.0.0.128/25)"]
            NAT[NAT Gateway\nSalida segura a Internet]
        end

        subgraph Subredes_Privadas_App ["Capa de Aplicación: EKS Worker Nodes (10.0.1.0/25, 10.0.1.128/25)"]
            subgraph NodeGroup ["EKS Managed Node Group (2 a 4 nodos Multi-AZ)"]
                subgraph Pods_Namespace ["Namespace: freshbox (10 Pods en Ejecución)"]
                    Pod_Front1[Pod: frontend-1]
                    Pod_Front2[Pod: frontend-2]
                    Pod_Get1[Pod: get-products-1]
                    Pod_Get2[Pod: get-products-2]
                    Pod_Create1[Pod: create-product-1]
                    Pod_Create2[Pod: create-product-2]
                    Pod_Update1[Pod: update-product-1]
                    Pod_Update2[Pod: update-product-2]
                    Pod_Delete1[Pod: delete-product-1]
                    Pod_Delete2[Pod: delete-product-2]
                end
                HPA[HPA Autoscalers\nTarget CPU 70% | Min 2 - Max 5] -.-> Pods_Namespace
            end
        end

        subgraph Subredes_Privadas_Data ["Capa de Datos: Amazon RDS PaaS (10.0.2.0/25, 10.0.2.128/25)"]
            RDS_Primary[(RDS MySQL Primaria\nus-east-1a\nLectura / Escritura)]
            RDS_Standby[(RDS MySQL Standby\nus-east-1b\nReplicación Sincrónica)]
            RDS_Primary <-->|Replicación Síncrona| RDS_Standby
        end
    end

    ECR[Amazon ECR\n5 Repositorios Docker] -.->|Pull Images via NAT| NodeGroup
    CloudWatch[CloudWatch Container Insights] -.->|Métricas y Logs| NodeGroup
    Pods_Namespace -->|MySQL :3306| RDS_Primary
```

---

## 4. Estructura de Microservicios en Kubernetes

Cada funcionalidad del catálogo se encuentra desacoplada en su propio **Deployment**, expuesta internamente mediante un **Service (ClusterIP)** y autoescalada por un **HorizontalPodAutoscaler (HPA)**:

| Microservicio | Imagen ECR | Puerto | Endpoint / Método | Réplicas (Min-Max) | Recurso CPU (Req/Lim) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **frontend** | `freshbox-frontend:latest` | `80` | `/` (Web UI y Reverse Proxy) | 2 - 5 | 50m / 200m |
| **get-products** | `freshbox-get-products:latest` | `3001` | `/api/products` (GET) | 2 - 5 | 100m / 250m |
| **create-product** | `freshbox-create-product:latest` | `3002` | `/api/products` (POST) | 2 - 5 | 100m / 250m |
| **update-product** | `freshbox-update-product:latest` | `3003` | `/api/products/:id` (PUT) | 2 - 5 | 100m / 250m |
| **delete-product** | `freshbox-delete-product:latest` | `3004` | `/api/products/:id` (DELETE) | 2 - 5 | 100m / 250m |

---

## 5. Estructura del Repositorio

```text
freshbox-cloud-architecture/
├── app/
│   ├── init.sql                               # Script DDL y datos de prueba para RDS MySQL
│   ├── microservicioFrontend/                 # Frontend estático HTML/JS + Nginx API Gateway
│   └── microserviciosBackend/                 # APIs Node.js/Express independientes
│       ├── create-product/
│       ├── delete-product/
│       ├── get-products/
│       └── update-product/
├── k8s/                                       # Manifiestos de Kubernetes para EKS
│   ├── namespace.yaml                         # Namespace 'freshbox'
│   ├── configmap.yaml                         # Parámetros DB_HOST, DB_NAME, DB_PORT
│   ├── secret.yaml                            # Credenciales DB_USER y DB_PASS en Base64
│   ├── frontend-deployment.yaml               # Deployment + Service ClusterIP Frontend
│   ├── get-products-deployment.yaml           # Deployment + Service ClusterIP GET
│   ├── create-product-deployment.yaml         # Deployment + Service ClusterIP POST
│   ├── update-product-deployment.yaml         # Deployment + Service ClusterIP PUT
│   ├── delete-product-deployment.yaml         # Deployment + Service ClusterIP DELETE
│   ├── ingress.yaml                           # Ingress ALB (AWS Load Balancer Controller)
│   ├── hpa-frontend.yaml                      # HPA Frontend (Min 2, Max 5, CPU 70%)
│   ├── hpa-get-products.yaml                  # HPA GET API (Min 2, Max 5, CPU 70%)
│   ├── hpa-create-product.yaml                # HPA POST API (Min 2, Max 5, CPU 70%)
│   ├── hpa-update-product.yaml                # HPA PUT API (Min 2, Max 5, CPU 70%)
│   └── hpa-delete-product.yaml                # HPA DELETE API (Min 2, Max 5, CPU 70%)
├── terraform/                                 # Infraestructura como Código (IaC)
│   ├── main.tf                                # Provider AWS, LabRole y data sources
│   ├── vpc.tf                                 # VPC con 6 subredes y tags para Kubernetes
│   ├── security-groups.tf                     # SGs encadenados: ALB -> EKS Nodes -> RDS
│   ├── eks.tf                                 # EKS Cluster + Managed Node Group Multi-AZ
│   ├── rds.tf                                 # Amazon RDS MySQL Multi-AZ PaaS
│   ├── ecr.tf                                 # 5 Repositorios en Amazon ECR
│   ├── budgets.tf                             # Gobernanza FinOps y AWS Budgets
│   ├── variables.tf                           # Variables tipadas para EKS y RDS
│   ├── outputs.tf                             # Kubeconfig command, RDS endpoint, ECR URLs
│   └── legacy_eva1/                           # Archivos históricos de ECS/EC2 de EVA1
├── scripts/                                   # Automatización multiplataforma (Bash & PowerShell)
│   ├── build-and-push.sh / .ps1               # Construcción y publicación de imágenes a ECR
│   ├── deploy-k8s.sh / .ps1                   # Configuración kubeconfig y despliegue K8s
│   ├── init-rds-db.sh                         # Inicialización de tablas MySQL via Pod efímero
│   └── test-crud.sh / .ps1                    # Pruebas automatizadas CRUD vía ALB Ingress
├── docs/                                      # Documentación técnica, informe y evidencias
└── README.md                                  # Este archivo
```

---

## 6. Guía de Despliegue Paso a Paso

### 6.1. Prerrequisitos
- Cuenta activa en **AWS Academy Learner Lab**.
- AWS CLI configurado con las credenciales temporales del laboratorio.
- Terraform CLI (v1.5+).
- Docker Desktop o Docker Engine.
- `kubectl` instalado localmente.

---

### Paso 1: Aprovisionar Infraestructura con Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```
*Terraform creará la VPC de 6 subredes con tags de EKS, el Clúster Amazon EKS, el Node Group Multi-AZ, la base de datos Amazon RDS MySQL Multi-AZ y los 5 repositorios ECR.*

---

### Paso 2: Construir y Publicar Imágenes en ECR
Desde la raíz del repositorio:
```bash
# En Linux / macOS / WSL / Git Bash:
./scripts/build-and-push.sh

# En Windows PowerShell:
.\scripts\build-and-push.ps1
```

---

### Paso 3: Desplegar Manifiestos en Amazon EKS
```bash
# En Linux / macOS / WSL / Git Bash:
./scripts/deploy-k8s.sh

# En Windows PowerShell:
.\scripts\deploy-k8s.ps1
```
*Este script actualiza automáticamente el `kubeconfig`, obtiene el endpoint de RDS creado por Terraform, inyecta las variables en los manifiestos YAML y aplica los 10 Pods, 5 Services, el Ingress ALB y los 5 HPAs en el namespace `freshbox`.*

---

### Paso 4: Inicializar la Base de Datos en RDS MySQL
Para cargar las tablas y los productos orgánicos de FreshBox sin necesidad de abrir puertos a internet:
```bash
./scripts/init-rds-db.sh
```

---

### Paso 5: Validar Despliegue de Recursos
Verifica que los 10 Pods estén en estado `Running` y distribuidos en los nodos trabajadores:
```bash
kubectl get pods -n freshbox -o wide
kubectl get svc -n freshbox
kubectl get ingress -n freshbox
kubectl get hpa -n freshbox
```

---

## 7. Pruebas Funcionales CRUD (Evaluación EA2)

Ejecuta el script automatizado de pruebas sobre el DNS público del ALB:
```bash
# En Linux / Bash:
./scripts/test-crud.sh

# En Windows PowerShell:
.\scripts\test-crud.ps1
```

O ejecuta manualmente las pruebas con `curl`:
```bash
# Obtener DNS del ALB Ingress
ALB_DNS=$(kubectl get ingress freshbox-ingress -n freshbox -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# 1. GET - Listar catálogo de productos
curl -i http://$ALB_DNS/api/products

# 2. POST - Crear nuevo producto orgánico
curl -i -X POST http://$ALB_DNS/api/products \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Frutillas Organicas 500g","descripcion":"Cultivo limpio de temporada","precio":3290,"stock":75,"categoria":"Frutas"}'

# 3. PUT - Modificar producto existente
curl -i -X PUT http://$ALB_DNS/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Manzanas Organicas Premium","descripcion":"Bolsa 1.5kg certificada","precio":3890,"stock":90,"categoria":"Frutas"}'

# 4. DELETE - Eliminar producto
curl -i -X DELETE http://$ALB_DNS/api/products/6
```

---

## 8. Entregables y Verificables para la Evaluación EA2

Siguiendo la pauta oficial de la **Actividad 2.3**, los verificables requeridos son:
1. **Clúster EKS activo:** Captura de pantalla de la consola AWS mostrando el clúster `freshbox-cluster` en estado `Active`.
2. **`kubectl get pods` con 10 Pods Running:** 2 réplicas por cada uno de los 5 microservicios (`frontend`, `get-products`, `create-product`, `update-product`, `delete-product`).
3. **`kubectl get ingress` con ALB DNS:** Mostrando el Application Load Balancer creado y asociado a las subredes públicas.
4. **`kubectl get hpa` con métricas activas:** Mostrando las 5 políticas HPA con target de 70% CPU.
5. **RDS Multi-AZ activo:** Captura de la consola RDS mostrando `Multi-AZ: Yes` y la réplica standby en la segunda AZ.
6. **Frontend web operativo:** Captura del navegador accediendo vía el DNS del ALB y mostrando el catálogo dinámico de productos.
7. **Pruebas CRUD exitosas:** Respuestas HTTP 200/201 en las 4 operaciones.
8. **CloudWatch Container Insights:** Gráficos de uso de CPU/memoria a nivel de pod y nodo.

---

## 9. Respuestas a Preguntas de Reflexión (Actividad 2.3)

### 1. ¿Qué diferencias notaste entre desplegar con Docker manual (EA1) vs Kubernetes (EA2)?
- **Automatización y Autorreparación:** En Docker manual, si un contenedor falla o el host se cae, el servicio queda inactivo hasta intervención humana. En Kubernetes, el Deployment detecta discrepancias en el estado deseado y recrea el Pod inmediatamente sin downtime.
- **Service Discovery y Balanceo Nativo:** En EA1 se requería configurar enlaces manuales o proxies estáticos. En Kubernetes, los `Services` de tipo `ClusterIP` proveen un balanceador interno y resolución DNS automática (`get-products:3001`).
- **Escalamiento Declarativo:** Con Kubernetes y HPA, el escalamiento horizontal de réplicas es automático basado en métricas de consumo de CPU/RAM, a diferencia de scripts manuales.

### 2. ¿Cómo respondió el HPA ante la prueba de carga?
Al someter a prueba de estrés los microservicios backend con solicitudes concurrentes que elevaron la utilización de CPU por encima del umbral del 70%, el controlador HPA incrementó progresivamente el número de réplicas de 2 hasta 5 pods. Una vez cesada la carga de tráfico y transcurrido el periodo de estabilización (*cooldown*), el HPA redujo ordenadamente las réplicas al valor mínimo configurado (2 réplicas), optimizando el uso de recursos.

### 3. ¿Qué ventaja tiene RDS Multi-AZ vs EC2 MySQL con AWS Backup?
- **RTO y RPO:** EC2 con AWS Backup requiere restaurar una instantánea (*snapshot*) en un nuevo volumen o servidor, lo que implica un **RTO de 30 a 90 minutos** y un **RPO dependiente de la frecuencia del respaldo** (pérdida de datos entre respaldos). En contraste, **Amazon RDS Multi-AZ** realiza una replicación sincrónica a nivel de almacenamiento hacia una zona secundaria, logrando un **RTO menor a 60 segundos** (failover automático sin intervención humana) y un **RPO = 0** (sin pérdida transaccional).
- **Cero mantenimiento operativo:** RDS gestiona automáticamente el aprovisionamiento de parches del sistema operativo y motor de base de datos, rotación de certificados y copias de seguridad continuas.

### 4. ¿Qué problemas encontraste y cómo los resolviste?
- **Compatibilidad con AWS Academy Learner Lab:** Las restricciones de IAM impiden la creación libre de nuevos roles para clústeres EKS. Se resolvió parametrizando Terraform para vincular el recurso `LabRole` preexistente (`data.aws_iam_role.lab_role`).
- **Enrutamiento por Método HTTP:** ALB Ingress no enruta nativamente por método HTTP (GET/POST/PUT/DELETE) a diferentes Target Groups bajo un mismo path. Se resolvió implementando Nginx en el microservicio Frontend como API Gateway interno que enruta hacia los servicios ClusterIP de Kubernetes mediante CoreDNS.

---

2026 - FreshBox SpA Cloud Architecture Team
