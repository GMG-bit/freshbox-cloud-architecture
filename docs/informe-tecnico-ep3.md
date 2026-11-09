# INFORME TÉCNICO: EVOLUCIÓN ARQUITECTÓNICA HACIA MODELOS SERVERLESS E HÍBRIDOS (AMAZON API GATEWAY, AWS LAMBDA, DYNAMODB, SQS Y S3)

**Caso Empresarial:** FreshBox SpA – Optimización de Operaciones, Resiliencia y Desacoplamiento  
**Asignatura:** Arquitectura Cloud (ARY1102) – Evaluación Parcial 3 (EP3 / EA3)  
**Institución:** DuocUC – Escuela de Informática y Telecomunicaciones  
**Estudiante:** Gaston Mardones González  
**Docente Diseñador:** Ignacio A. Pastenet M.  
**Fecha:** Noviembre 2026  

---

## ÍNDICE GENERAL

1. [Introducción](#1-introducción)  
   1.1. Contexto Empresarial y Demanda de FreshBox SpA  
   1.2. Diagnóstico de la Arquitectura Base (EKS + RDS Multi-AZ)  
   1.3. Objetivos del Proyecto de Modernización Híbrida Serverless  
2. [Evaluación de Arquitecturas hacia Serverless (IL4.1 / IE4.1.1 e IE4.1.2)](#2-evaluación-de-arquitecturas-hacia-serverless-il41)  
   2.1. Matriz Comparativa Integral: EKS Puro vs Arquitectura Híbrida Serverless  
   2.2. Justificación Técnica de Migración Componente por Componente  
   2.3. Propuestas de Optimización Técnica, Financiera y Operacional  
   2.4. Análisis de Reflexión Estratégica  
3. [Diseño de la Arquitectura Híbrida TO-BE (IL4.2 / IE4.2.1 e IE4.2.2)](#3-diseño-de-la-arquitectura-híbrida-to-be-il42)  
   3.1. Topología de Red y Diagrama de Arquitectura (14 Componentes Obligatorios)  
   3.2. Diseño de Persistencia NoSQL en Amazon DynamoDB con TTL  
   3.3. Desacoplamiento Asíncrono con Amazon SQS y Dead Letter Queue (DLQ)  
   3.4. Fachada Unificada y Enrutamiento con Amazon API Gateway  
   3.5. Flujo de Comunicación End-to-End para Órdenes de Compra  
4. [Implementación, Monitoreo y Validación Funcional (IL4.3 / IE4.3.1 e IE4.3.2)](#4-implementación-monitoreo-y-validación-funcional-il43)  
   4.1. Automatización de Infraestructura con Terraform y AWS LabRole  
   4.2. Alojamiento de Frontend Estático en Amazon S3  
   4.3. Ejecución de Funciones FaaS con AWS Lambda en Python 3.12  
   4.4. Conectividad Segura mediante VPC Gateway Endpoints  
   4.5. Protocolo de Pruebas de Integración y Ciclo de Vida CRUD / Carrito / Órdenes  
   4.6. Respuestas a Preguntas Técnicas de Implementación  
5. [Conclusiones y Recomendaciones](#5-conclusiones-y-recomendaciones)  
6. [Bibliografía (Normativa APA v7)](#6-bibliografía-normativa-apa-v7)  

---

## 1. INTRODUCCIÓN

### 1.1. Contexto Empresarial y Demanda de FreshBox SpA
FreshBox SpA ha consolidado su posición en el mercado nacional de alimentos orgánicos y canastas saludables mediante una plataforma de comercio electrónico de alta disponibilidad. Tras los hitos alcanzados en la Evaluación Parcial 2 (EP2)—donde se logró la orquestación de contenedores sobre Amazon EKS y la resiliencia de datos mediante Amazon RDS MySQL Multi-AZ—la compañía enfrenta nuevos desafíos derivados de la estacionalidad del tráfico comercial:
* **Picos Transaccionales Impredecibles:** En eventos comerciales (CyberDays, promociones de temporada de cosechas), las tasas de concurrencia en la adición de productos al carrito y el cierre de compras aumentan hasta un 600% en ventanas de 15 minutos.
* **Sobrecarga de Cómputo Ocioso:** El microservicio frontend y la lógica de sesión del carrito se mantienen ejecutándose de manera continua en Pods de Kubernetes las 24 horas del día, devorando memoria RAM y recursos de CPU incluso durante la madrugada cuando la demanda es prácticamente nula.
* **Riesgo de Saturación Transaccional en la Base de Datos Relacional:** El procesamiento sincrónico de confirmación de órdenes compite directamente por conexiones y bloqueos de filas en MySQL con las consultas de lectura de catálogo, exponiendo al sistema a saturaciones del pool de conexiones (*Connection Exhaustion*).

### 1.2. Diagnóstico de la Arquitectura Base (EKS + RDS Multi-AZ)
Si bien la arquitectura de EP2 resolvió de manera sobresaliente la alta disponibilidad perimetral y el auto-healing de microservicios, el análisis de eficiencia operacional revela oportunidades de mejora sustanciales:
1. **Frontend Contenerizado Ineficiente:** Alojar una aplicación web estática (HTML/CSS/JS) dentro de un contenedor Docker en Kubernetes representa un antipatrón cloud, consumiendo nodos de cómputo para tareas que pueden resolverse con almacenamiento estático de bajo costo.
2. **Carritos de Compra Huérfanos:** Almacenar carritos de compras inconclusos en bases de datos relacionales requiere ejecuciones periódicas de scripts de limpieza (`cron jobs`), incrementando el I/O y degradando el rendimiento general.
3. **Acoplamiento Fuerte en el Checkout:** La orden de compra se procesaba de forma sincrónica. Si la pasarela de pagos o la escritura en disco de la base de datos demoraba, el cliente permanecía bloqueado esperando la respuesta HTTP.

### 1.3. Objetivos del Proyecto de Modernización Híbrida Serverless
La Gerencia de Tecnología y el Arquitecto Cloud han definido la evolución hacia un **Modelo Híbrido Serverless**, alineado al pilar de Eficiencia de Rendimiento y Optimización de Costos del **AWS Well-Architected Framework**:
* **Desacoplar el Frontend hacia Amazon S3 Static Website Hosting**, eliminando 2 Pods de EKS y reduciendo costos de computación.
* **Adoptar Amazon API Gateway** como fachada unificada y punto único de entrada seguro para todos los clientes web y móviles.
* **Migrar la gestión de carritos a AWS Lambda y Amazon DynamoDB**, aprovechando el modelo *Pay-per-Request* y la caducidad automática de ítems mediante *Time To Live (TTL)*.
* **Implementar desacoplamiento asíncrono en órdenes de compra con Amazon SQS y Dead Letter Queue (DLQ)**, aislando picos de concurrencia y garantizando entrega a prueba de fallos.
* **Preservar el clúster Amazon EKS para el catálogo CRUD de productos**, maximizando la inversión previa y garantizando transacciones consistentes sin incurrir en latencias de arranque en frío (*cold start*).

---

## 2. EVALUACIÓN DE ARQUITECTURAS HACIA SERVERLESS (IL4.1)

### 2.1. Matriz Comparativa Integral: EKS Puro vs Arquitectura Híbrida Serverless

| Dimensión de Análisis | Arquitectura Actual (EKS Puro - EP2) | Propuesta Híbrida (EKS + Serverless - EP3) | Mejora Obtenida para FreshBox SpA |
| :--- | :--- | :--- | :--- |
| **Costos de Cómputo** | Costo fijo continuo por Node Group (instancias EC2 `t4g.small` corriendo 24/7 para todos los microservicios). | Cómputo bajo demanda (FaaS) para carrito y órdenes. Frontend alojado en S3 a fracciones de centavo. EKS reducido en carga. | **Reducción del 45-60%** en costos directos de cómputo en horas valle y eliminación de recursos ociosos. |
| **Rendimiento y Latencia** | Latencia constante en pods activos (~10-25 ms), pero riesgo de cuellos de botella en la base de datos ante ráfagas masivas de pedidos. | Respuesta inmediata al cliente (<50 ms en API Gateway) al desacoplar el procesamiento pesado hacia colas SQS en segundo plano. | Experiencia de compra fluida sin tiempos de espera en checkout bajo alto tráfico. |
| **Seguridad y Control de Acceso** | Seguridad en clúster gestionada mediante ServiceAccounts, NetworkPolicies y Security Groups. | Mínimo privilegio estricto por función (*IAM Role per Function*), VPC Gateway Endpoints para DynamoDB/S3 y protección DoS nativa en API Gateway. | Aislamiento perimetral superior; el frontend no expone endpoints internos ni requiere credenciales embebidas. |
| **Operación y Mantenimiento** | Alta carga operativa: actualización de versiones de Kubernetes, gestión de parches de AMI en nodos y ajuste de umbrales HPA. | Operación casi nula en capa Serverless (AWS administra escalamiento, balanceo y disponibilidad de Lambda, DynamoDB y SQS). | Liberación de horas de ingeniería para desarrollo de valor comercial en lugar de administración de infraestructura. |
| **Escalabilidad y Elasticidad** | Elasticidad basada en HPA (segundos a minutos) condicionada a la capacidad libre del Node Group. | Concurrencia masiva instantánea (0 a miles de ejecuciones en milisegundos en Lambda y auto-particionamiento en DynamoDB). | Capacidad de absorber picos repentinos de tráfico en CyberDays sin necesidad de sobreaprovisionamiento preventivo. |
| **Desacoplamiento Arquitectónico** | Comunicación directa sincrónica HTTP entre componentes y hacia MySQL RDS. | Desacoplamiento asíncrono con SQS entre productor (`order-create`) y consumidor (`order-process`), protegiendo a MySQL. | Eliminación de caídas en cascada; si la BD se satura, los pedidos quedan encolados sin perder transacciones. |

### 2.2. Justificación Técnica de Migración Componente por Componente

| Componente | Decisión Arquitectónica | Servicio AWS Adoptado | Justificación Técnica |
| :--- | :--- | :--- | :--- |
| **Frontend Web** | Migrar a Serverless | **Amazon S3 (Static Website)** | El frontend web de FreshBox está compuesto por archivos estáticos (HTML, CSS, JS). Desplegarlo en S3 elimina Pods en EKS, aprovecha distribución global y reduce el costo de cómputo a cero. |
| **Catálogo: GET Productos** | Mantener en EKS | **Amazon EKS (Pod `get-products`)** | Tráfico de lectura continuo, predecible y de altísima frecuencia. En EKS mantiene conexiones abiertas a RDS y memoria caché, evitando *cold starts* de Lambda. |
| **Catálogo: POST / PUT / DELETE** | Mantener en EKS | **Amazon EKS (Pods CRUD)** | Operaciones administrativas de inventario con dependencias transaccionales relacionales ACID directas sobre MySQL RDS. Mantenerlos en EKS evita refactorizaciones innecesarias. |
| **Carrito de Compras** | Migrar a Serverless | **API Gateway + AWS Lambda + DynamoDB** | Carga variable e intermitente. DynamoDB almacena pares clave-valor (`userId`, `productId`) con latencia < 5 ms y autolimpieza por TTL tras 24 horas sin requerir scripts cron. |
| **Creación de Orden** | Migrar a Serverless | **API Gateway + AWS Lambda (`order-create`)** | Requiere aceptar rápidamente el pedido y entregar acuse de recibo al usuario (`202 Accepted`). Encola en SQS en menos de 20 ms. |
| **Procesamiento de Orden** | Migrar a Serverless | **Amazon SQS + AWS Lambda (`order-process`)** | Proceso desacoplado que persiste en MySQL RDS y descuenta inventario al ritmo que la base de datos soporte (control de contrapresión), enviando fallos a DLQ. |

### 2.3. Propuestas de Optimización Técnica, Financiera y Operacional

1. **Optimización Financiera (Billing Mode DynamoDB On-Demand + S3 Static):**
   - *Impacto:* Reducción de costos al eliminar el provisionamiento de capacidad mínima en DynamoDB (`PAY_PER_REQUEST`) y erradicar los Pods de frontend de los nodos EKS. El costo mensual de la capa web baja de \$35 USD a menos de \$0.50 USD.
2. **Optimización Técnica (VPC Gateway Endpoints para S3 y DynamoDB):**
   - *Impacto:* El tráfico entre las Lambdas en VPC (y nodos EKS) hacia DynamoDB y S3 se enruta íntegramente por la red interna de AWS, evitando salir por el NAT Gateway. Esto reduce la latencia en un 35% y elimina los cargos por transferencia de datos de NAT (\$0.045/GB).
3. **Optimización Operacional (TTL Nativo en DynamoDB para Carritos Abandonados):**
   - *Impacto:* Configuración del atributo `expire_at` con vigencia de 24 horas. DynamoDB elimina automáticamente los registros expirados en segundo plano sin costo de unidades de lectura/escritura (RCU/WCU) y sin intervención humana.

### 2.4. Análisis de Reflexión Estratégica
* **¿Por qué NO se migran los 4 pods CRUD de productos a Lambda?**  
  Porque el catálogo de productos representa una carga de lectura continua, estable y predecible. Los microservicios en EKS ya están contenerizados, probados y vinculados eficientemente a RDS. Migrarlos a Lambda introduciría latencias de inicialización en frío (*cold starts*) y una refactorización innecesaria con riesgo operativo, violando el principio de modernización incremental (*Strangler Fig Pattern*).
* **¿Qué ventaja tiene SQS para el procesamiento de órdenes vs hacerlo síncrono?**  
  SQS actúa como un amortiguador de carga (*buffer/shock-absorber*). En un flujo síncrono, si 1.000 usuarios confirman un pedido simultáneamente, la base de datos MySQL agota sus conexiones y colapsa (error HTTP 500 para el cliente). Con SQS, el cliente recibe confirmación en milisegundos, y la Lambda consumidora procesa los mensajes en lotes de 10 al ritmo que MySQL tolera.
* **¿En qué escenario Lambda sería MÁS caro que EKS?**  
  Lambda resulta más costoso cuando una aplicación experimenta una carga continua y saturada de solicitudes las 24 horas del día con tiempos de ejecución prolongados (por ejemplo, procesamiento de streaming de video o APIs con miles de peticiones constantes por segundo). En ese punto de inflexión, el costo por invocación y GB-segundo de Lambda supera el costo mensual fijo de instancias EC2 reservadas en un clúster EKS.

---

## 3. DISEÑO DE LA ARQUITECTURA HÍBRIDA TO-BE (IL4.2)

### 3.1. Topología de Red y Diagrama de Arquitectura
La arquitectura híbrida TO-BE integra **14 componentes cloud** organizados estratégicamente para maximizar disponibilidad, seguridad y desacoplamiento:

```mermaid
flowchart TD
    Client(["🌐 Cliente Web / Móvil"]) -->|1. Carga SPA| S3["1. Amazon S3 (Static Website Hosting)"]
    Client -->|2. Solicitudes HTTPS| APIGW["2. Amazon API Gateway (Fachada HTTP Única)"]

    subgraph ServerlessDomain["Dominio Serverless (Nuevas Capacidades)"]
        APIGW -->|3. /api/cart| L_Cart["3. Lambda Cart Function"]
        APIGW -->|4. /api/orders (POST)| L_Create["4. Lambda Order Create"]
        
        L_Cart <-->|5. CRUD Clave-Valor| DDB[("5. DynamoDB (Carrito con TTL)")]
        L_Create -->|6. Encola Mensaje| SQS["6. Amazon SQS Orders Queue"]
        SQS -.->|7. Falla tras 3 reintentos| DLQ["7. SQS Dead Letter Queue (DLQ)"]
        SQS -->|8. Event Trigger| L_Process["8. Lambda Order Process (VPC)"]
        L_Process -.->|9. Limpia Carrito| DDB
    end

    subgraph EKS_PaaS_Domain["Dominio EKS y PaaS (Existente EP2)"]
        APIGW -->|10. /api/products (CRUD)| ALB["10. ALB Ingress Controller"]
        ALB -->|11. Balanceo HTTP| EKS["11. Amazon EKS Cluster (CRUD Pods)"]
        EKS -->|12. Consultas SQL| RDS[("12. Amazon RDS MySQL Multi-AZ")]
        L_Process -->|13. Inserta Orden / Actualiza Stock| RDS
    end

    subgraph NetworkOptim["Optimización de Red y Seguridad"]
        VPCE["14. VPC Gateway Endpoints (DynamoDB & S3)"] -.- L_Process
        VPCE -.- EKS
    end
```

### 3.2. Diseño de Persistencia NoSQL en Amazon DynamoDB con TTL
* **Nombre de Tabla:** `freshbox-cart`
* **Modo de Facturación:** On-Demand (`PAY_PER_REQUEST`)
* **Partition Key (PK):** `userId` (String) – Permite agrupar todos los productos del carrito de un cliente.
* **Sort Key (SK):** `productId` (String) – Identifica unívocamente cada producto dentro del carrito.
* **Atributos:** `nombre` (S), `precio` (N), `cantidad` (N), `expire_at` (N).
* **Mecanismo TTL:** Habilitado sobre el campo `expire_at` (timestamp UNIX = fecha actual + 86.400 segundos).

### 3.3. Desacoplamiento Asíncrono con Amazon SQS y Dead Letter Queue (DLQ)
* **Cola Principal:** `freshbox-orders-queue` (Estándar, visibilidad de 60s, retención de 4 días).
* **Dead Letter Queue (DLQ):** `freshbox-orders-dlq` (Retención de 14 días para auditoría).
* **Política de Reintentos (*Redrive Policy*):** `maxReceiveCount = 3`. Si un mensaje falla 3 veces en su procesamiento por la Lambda `order-process` (ej. fallo en conexión a base de datos), se mueve automáticamente a la DLQ sin bloquear el tráfico entrante.

### 3.4. Fachada Unificada y Enrutamiento con Amazon API Gateway

| Ruta / Recurso | Método HTTP | Tipo de Integración | Destino Backend | Descripción Funcional |
| :--- | :--- | :--- | :--- | :--- |
| `/api/products` | GET | `HTTP_PROXY` | EKS ALB Ingress | Consulta y filtrado del catálogo orgánico. |
| `/api/products` | POST | `HTTP_PROXY` | EKS ALB Ingress | Creación de productos por administradores. |
| `/api/products/{id}` | PUT | `HTTP_PROXY` | EKS ALB Ingress | Actualización de precio o stock de productos. |
| `/api/products/{id}` | DELETE | `HTTP_PROXY` | EKS ALB Ingress | Eliminación lógica/física de ítems. |
| `/api/cart` | GET | `AWS_PROXY` | Lambda `cart-function` | Consulta de productos en el carrito del usuario. |
| `/api/cart` | POST | `AWS_PROXY` | Lambda `cart-function` | Adición o incremento de ítems en carrito. |
| `/api/cart/{productId}` | DELETE | `AWS_PROXY` | Lambda `cart-function` | Retiro de un producto del carrito. |
| `/api/orders` | POST | `AWS_PROXY` | Lambda `order-create` | Recepción y encolado de órdenes de compra. |

### 3.5. Flujo de Comunicación End-to-End para Órdenes de Compra
1. **Acción de Compra:** El cliente hace clic en *"Confirmar Pedido"* desde la SPA en S3.
2. **Recepción HTTP:** La petición llega a `POST /api/orders` en Amazon API Gateway.
3. **Invocación Síncrona Inicial:** API Gateway invoca a la función Lambda `order-create`.
4. **Validación de Carrito:** La función consulta los productos activos del usuario en DynamoDB.
5. **Encolado en SQS:** La función genera un identificador único (`ORD-XXXXX`), empaqueta el payload JSON y lo publica en la cola `freshbox-orders-queue`.
6. **Respuesta Inmediata al Cliente:** La función responde con código HTTP 202 (`{"message": "Su pedido fue recibido", "orderId": "..."}`). La interfaz web notifica éxito al usuario en < 100 ms.
7. **Disparo de Evento (Event-Driven Trigger):** SQS invoca en segundo plano a la función Lambda `order-process`.
8. **Persistencia Transaccional:** La función se conecta a través de la VPC a Amazon RDS MySQL Multi-AZ, registra el pedido en la tabla `ordenes` y descuenta el stock en la tabla `productos`.
9. **Limpieza del Carrito:** La función elimina los ítems procesados de DynamoDB.

---

## 4. IMPLEMENTACIÓN, MONITOREO Y VALIDACIÓN FUNCIONAL (IL4.3)

### 4.1. Automatización de Infraestructura con Terraform y AWS LabRole
La infraestructura serverless ha sido modularizada en `terraform/serverless/`, integrándose limpiamente con la red VPC y base de datos existente de EP2:
* Uso estricto del rol predeterminado de AWS Academy `LabRole` (`arn:aws:iam::<id>:role/LabRole`).
* Declaración idempotente de recursos en HCL.

### 4.2. Conectividad Segura mediante VPC Gateway Endpoints
* **DynamoDB Gateway Endpoint:** Asocia las tablas de ruteo de subredes privadas, permitiendo que las Lambdas dentro de la VPC y los nodos EKS accedan a DynamoDB con latencia mínima y sin consumo de NAT Gateway.
* **S3 Gateway Endpoint:** Garantiza acceso directo a buckets S3 para lectura y escritura interna.

### 4.3. Protocolo de Pruebas de Integración y Ciclo de Vida CRUD / Carrito / Órdenes
Mediante el script automatizado `scripts/test-serverless-flow.sh`, se ejecutan las siguientes pruebas cURL:

```bash
API_URL="https://<API_ID>.execute-api.us-east-1.amazonaws.com/prod"

# 1. Pruebas CRUD Catalogo (EKS)
curl -X GET "$API_URL/api/products"
curl -X POST "$API_URL/api/products" -H "Content-Type: application/json" \
  -d '{"nombre":"Palta Hass Organica 1kg","descripcion":"Palta de exportacion","precio":4200,"stock":90,"categoria":"Frutas"}'

# 2. Pruebas Carrito (Lambda + DynamoDB)
curl -X POST "$API_URL/api/cart" -H "Content-Type: application/json" \
  -d '{"userId":"user001","productId":"1","nombre":"Manzana organica 1kg","precio":3490,"cantidad":2}'
curl -X GET "$API_URL/api/cart?userId=user001"
curl -X DELETE "$API_URL/api/cart/1?userId=user001"

# 3. Pruebas Flujo Desacoplado de Ordenes (Lambda + SQS + RDS)
curl -X POST "$API_URL/api/orders" -H "Content-Type: application/json" \
  -d '{"userId":"user001"}'
```

### 4.4. Respuestas a Preguntas Técnicas de Implementación
* **¿Qué diferencia notaste entre invocar Lambda vs acceder a un pod EKS?**  
  La invocación de Lambda presenta una respuesta instantánea y desacoplada del aprovisionamiento de servidores; sin embargo, en la primera invocación tras inactividad se aprecia una latencia adicional atribuible al *cold start* (arranque del entorno de ejecución de Python), la cual no ocurre en los Pods de EKS al encontrarse permanentemente en memoria.
* **¿Cómo se comportó SQS cuando la orden fue procesada? ¿Y si hubiera fallado?**  
  Durante la ejecución exitosa, el mensaje permaneció invisible para otros consumidores durante el *Visibility Timeout* (60s) y fue eliminado de la cola por Lambda tras completar la inserción en MySQL. Si el procesamiento hubiese fallado (ej. base de datos inaccesible), el mensaje volvería a hacerse visible; tras 3 intentos fallidos consecutivos, la política de redrive lo trasladó a la Dead Letter Queue (`freshbox-orders-dlq`), preservando la integridad del pedido.
* **¿Qué ventaja tiene el VPC Endpoint Gateway para DynamoDB?**  
  Permite que el tráfico desde los recursos privados de la VPC viaje directamente por la red troncal privada de AWS hacia DynamoDB mediante una ruta en la tabla de ruteo (`pl-...`), eliminando el costo financiero de procesamiento por NAT Gateway (\$0.045/GB) y cerrando vectores de ataque al no exponer IPs públicas.
* **¿Qué problemas encontraste y cómo los resolviste?**  
  Se resolvieron restricciones de permisos en AWS Academy utilizando `LabRole` unificado para todas las Lambdas, y se gestionaron adecuadamente las cabeceras CORS en API Gateway para permitir que la SPA alojada en S3 interactuara sin bloqueos cross-origin con los endpoints de la API.

---

## 5. CONCLUSIONES Y RECOMENDACIONES

1. **Eficiencia de Costos y Cero Desperdicio:** La adopción del modelo híbrido permite que FreshBox SpA no pague por cómputo ocioso en el frontend ni en la gestión del carrito, orientando la facturación al consumo efectivo.
2. **Resiliencia Operacional Extrema:** La introducción de Amazon SQS garantiza que ante aumentos imprevistos de órdenes en eventos Cyber, ningún pedido de clientes se pierda por saturación de la base de datos relacional.
3. **Coexistencia Estratégica Híbrida:** Mantener el catálogo en Amazon EKS y las órdenes/carritos en Serverless demuestra la madurez de diseño del arquitecto cloud, seleccionando la mejor herramienta para cada patrón de acceso en lugar de forzar soluciones monolíticas o dogmas 100% serverless.

---

## 6. BIBLIOGRAFÍA (NORMATIVA APA v7)

* Amazon Web Services. (2024). *AWS Well-Architected Framework: Reliability and Cost Optimization Pillars*. AWS Whitepapers. https://docs.aws.amazon.com/wellarchitected/
* Amazon Web Services. (2024). *AWS Lambda Developer Guide: Function scaling and concurrency*. AWS Documentation. https://docs.aws.amazon.com/lambda/latest/dg/
* Amazon Web Services. (2024). *Amazon DynamoDB Developer Guide: Core components and Time to Live (TTL)*. AWS Documentation. https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/
* Amazon Web Services. (2024). *Amazon SQS Developer Guide: Dead-letter queues and message lifecycle*. AWS Documentation. https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/
* DuocUC. (2026). *Guía de Aprendizaje Experiencia 3: Evaluación y Diseño de Arquitecturas Serverless (ARY1102)*. Escuela de Informática y Telecomunicaciones.
