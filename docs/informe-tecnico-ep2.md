# INFORME TÉCNICO: MODERNIZACIÓN DE ARQUITECTURA CLOUD MEDIANTE ORQUESTACIÓN DE CONTENEDORES (AMAZON EKS) Y SERVICIOS PAAS (AMAZON RDS MULTI-AZ)

**Caso Empresarial:** FreshBox SpA — Evolución Tecnológica y Continuidad Operativa  
**Asignatura:** Arquitectura Cloud (ARY1102) — Evaluación Parcial 2 (EP2)  
**Institución:** DuocUC — Escuela de Informática y Telecomunicaciones  
**Estudiante:** Gaston Mardones González  
**Docente Diseñador:** Ignacio A. Pastenet M.  
**Fecha:** Octubre 2026  

---

## ÍNDICE GENERAL

1. [Introducción](#1-introducción)
   1.1. Contexto Empresarial de FreshBox SpA  
   1.2. Problemática y Limitaciones de la Arquitectura Base (EA1)  
   1.3. Objetivos del Proyecto de Modernización  
2. [1.1 Análisis Diferencias entre Arquitecturas (IE3.1.1)](#2-11-análisis-diferencias-entre-arquitecturas-ie311)
   2.1. Comparativa Integral: Tradicional (EC2+Docker) vs Orquestación (EKS) vs PaaS  
   2.2. Matriz de Evaluación Técnica, Operacional y Financiera  
   2.3. Justificación Técnica de la Evolución hacia EKS y RDS Multi-AZ  
3. [1.2 Estrategia de Modernización Tecnológica (IE3.1.2)](#3-12-estrategia-de-modernización-tecnológica-ie312)
   3.1. Propuesta de Arquitectura Cloud-Native  
   3.2. Impacto Operacional, Técnico y de Negocio  
   3.3. Alineación con los Objetivos Estratégicos de FreshBox SpA  
4. [1.3 Mecanismos de Escalabilidad, Seguridad y Alta Disponibilidad (IE3.2.2)](#4-13-mecanismos-de-escalabilidad-seguridad-y-alta-disponibilidad-ie322)
   4.1. Elasticidad y Escalabilidad Automática (HPA y Node Groups)  
   4.2. Seguridad en Profundidad y Segmentación de Red  
   4.3. Alta Disponibilidad y Resiliencia Multi-AZ  
5. [Diseño de Arquitectura TO-BE y Flujo de Comunicación (IE3.2.1)](#5-diseño-de-arquitectura-to-be-y-flujo-de-comunicación-ie321)
   5.1. Topología de Red en 3 Capas  
   5.2. Flujo de Comunicación End-to-End  
   5.3. Mapeo de Componentes y Manifiestos Kubernetes  
6. [Implementación, Monitoreo y Validación Funcional (IE3.3.1 y IE3.3.2)](#6-implementación-monitoreo-y-validación-funcional-ie331-y-ie332)
   6.1. Automatización del Despliegue con Terraform y CI/CD  
   6.2. Estrategia de Validación del Ciclo CRUD  
   6.3. Observabilidad con Amazon CloudWatch Container Insights  
7. [Conclusiones y Recomendaciones](#7-conclusiones-y-recomendaciones)
8. [Bibliografía (Normativa APA v7)](#8-bibliografía-normativa-apa-v7)

---

## 1. INTRODUCCIÓN

### 1.1. Contexto Empresarial de FreshBox SpA
FreshBox SpA es una empresa chilena de comercio electrónico especializada en la distribución y comercialización de productos agrícolas orgánicos y alimentos saludables. Durante los últimos cuatro trimestres, la organización ha experimentado una tasa de crecimiento sostenida del **40% trimestral** en el volumen de transacciones de su plataforma web. Este vertiginoso ritmo de adopción ha transformado el canal digital en el principal motor de ingresos de la compañía, convirtiendo la disponibilidad, resiliencia y velocidad de respuesta de la infraestructura tecnológica en factores críticos de éxito empresarial.

### 1.2. Problemática y Limitaciones de la Arquitectura Base (EA1)
Durante la primera fase del proyecto de adopción cloud (Evaluación EA1), FreshBox implementó una arquitectura basada en el modelo de Infraestructura como Servicio (IaaS), desplegando contenedores Docker de forma manual sobre instancias Amazon EC2, acompañados de una base de datos relacional MySQL instalada en un servidor virtual independiente y respaldada periódicamente mediante AWS Backup. 

A pesar de haber cumplido con los objetivos iniciales de viabilidad funcional, la gerencia general y el área de TI han identificado serias limitaciones arquitectónicas que ponen en riesgo la continuidad operacional del negocio ante el incremento proyectado de la demanda:
1. **Gestión Manual de Contenedores:** La ausencia de un plano de orquestación implica que el ciclo de vida de los contenedores se administra manualmente mediante scripts SSH. Ante la caída imprevista de un proceso de microservicio, el sistema carece de autorreparación (*self-healing*), requiriendo intervención humana reactiva para reiniciar las cargas de trabajo.
2. **Escalamiento Rígido y No Granular:** El modelo de escalamiento se basa en duplicar instancias EC2 completas. Si el microservicio `get-products` experimenta un pico de demanda durante una campaña promocional, no es posible escalar dicho componente de forma aislada; es forzoso aprovisionar una máquina virtual completa con todos los microservicios redundantes, generando un sobrecosto severo por consumo de recursos ociosos.
3. **Base de Datos Monolítica sin Alta Disponibilidad Nativa:** La base de datos MySQL en EC2 constituye un punto único de falla (*Single Point of Failure - SPOF*). En caso de interrupción del hardware subyacente de la zona de disponibilidad o corrupción del sistema operativo, el mecanismo de recuperación ante desastres depende exclusivamente de la restauración de snapshots diarios desde AWS Backup. Esto impone un Objetivo de Tiempo de Recuperación (*Recovery Time Objective - RTO*) superior a varias horas y un Objetivo de Punto de Recuperación (*Recovery Point Objective - RPO*) de hasta 24 horas, lo cual se traduce en pérdidas millonarias directas y daño irreparable a la reputación corporativa.
4. **Sobrecarga Operativa de Mantenimiento:** La administración del sistema operativo (parches de seguridad del kernel de Linux, actualizaciones del motor MySQL, mantenimiento de librerías de Docker) absorbe más del 60% de las horas del equipo de ingeniería, distrayendo recursos estratégicos que deberían estar dedicados a la mejora del producto comercial.

### 1.3. Objetivos del Proyecto de Modernización
Con la finalidad de superar estas restricciones y preparar a FreshBox SpA para escalar sin fricciones, la gerencia ha encomendado al Arquitecto Cloud el rediseño e implementación de una solución tecnológica avanzada alineada a los pilares del **AWS Well-Architected Framework**:
* **Migrar las cargas de trabajo contenerizadas** desde instancias EC2 autogestionadas hacia un clúster elástico administrado con **Amazon EKS (Elastic Kubernetes Service)**, desacoplando los 5 microservicios en **10 Pods** (2 réplicas por componente) con autoescalado elástico granular mediante **Horizontal Pod Autoscaler (HPA)**.
* **Modernizar la capa de persistencia de datos** hacia un servicio gestionado de Plataforma como Servicio (PaaS) mediante **Amazon RDS MySQL Multi-AZ**, asegurando replicación síncrona en tiempo real entre zonas de disponibilidad, failover automático en menos de 60 segundos y cero pérdida de datos transaccionales (RPO = 0).
* **Consolidar la seguridad perimetral y segmentación en 3 capas** mediante Security Groups encadenados por principio de mínimo privilegio, cifrado en reposo para volúmenes EBS y almacenamiento de base de datos, y un punto de entrada centralizado a través de **Application Load Balancer (ALB) Ingress Controller**.
* **Automatizar completamente el aprovisionamiento** a través de Infraestructura como Código (IaC) con Terraform y flujos continuos de integración y entrega (CI/CD) con GitHub Actions.

---

## 2. 1.1 ANÁLISIS DIFERENCIAS ENTRE ARQUITECTURAS (IE3.1.1)

### 2.1. Comparativa Integral: Tradicional (EC2+Docker) vs Orquestación (EKS) vs PaaS
El análisis de modernización exige contrastar detalladamente el paradigma tradicional de Infraestructura como Servicio frente a los paradigmas contemporáneos de Orquestación de Contenedores y Plataforma como Servicio:

* **Arquitectura Tradicional (EC2 + Docker Manual):**  
  En este modelo, el usuario asume la responsabilidad casi absoluta del stack tecnológico (modelo de responsabilidad compartida). Se deben aprovisionar instancias virtuales, instalar el daemon de Docker, configurar archivos Docker Compose, abrir puertos en el host y vigilar constantemente que los contenedores no consuman la totalidad de la memoria RAM de la máquina virtual. Las actualizaciones implican detener el contenedor y desplegar uno nuevo con interrupción del servicio (*downtime*).
* **Orquestación de Contenedores con Amazon EKS:**  
  Kubernetes abstrae la infraestructura física y virtual en un único plano de cómputo elástico. AWS asume la alta disponibilidad, parches y resiliencia del plano de control (*Control Plane*), el cual corre distribuido en al menos tres zonas de disponibilidad. A través de especificaciones declarativas escritas en YAML, el arquitecto define el estado deseado (*Desired State*) de la aplicación. EKS se encarga de programar los pods en los nodos de trabajo (*Worker Nodes*), balancear la carga interna por DNS y supervisar constantemente la salud de los contenedores.
* **Servicios Gestionados PaaS (Amazon RDS MySQL Multi-AZ):**  
  La base de datos se transforma de una pieza de software instalada manualmente en un servicio cloud completamente gestionado. AWS se encarga del aprovisionamiento de hardware, el parcheo del motor de base de datos, la gestión de respaldos diarios automáticos con recuperación en el tiempo (*Point-in-Time Recovery - PITR*) y la replicación de bloques de almacenamiento a nivel físico entre centros de datos físicamente separados.

### 2.2. Matriz de Evaluación Técnica, Operacional y Financiera

| Criterio de Evaluación | Arquitectura AS-IS (EC2 + Docker Manual) | Arquitectura TO-BE (Amazon EKS + RDS Multi-AZ) | Ventaja Competitiva de la Solución TO-BE |
| :--- | :--- | :--- | :--- |
| **Mecanismo de Recuperación ante Fallos (Auto-healing)** | **Manual / Reactivo:** Si el contenedor falla, permanece inactivo hasta que un operador humano se conecta vía SSH para ejecutar `docker restart`. | **Automático / Declarativo:** EKS monitorea los pods mediante *Liveness* y *Readiness Probes*. Si un contenedor falla, el Kubelet lo destruye y lo recrea instantáneamente en un nodo sano en milisegundos. | Maximización de la disponibilidad continua (SLA 99.95%) y eliminación de tiempos de caída no planificados. |
| **Escalabilidad y Elasticidad de Carga** | **Brusca y Costosa:** Solo se puede escalar añadiendo otra instancia EC2 completa. Escalar tarda entre 5 a 8 minutos y aprovisiona todos los microservicios, incluso los que no tienen carga. | **Granular y Dinámica:** El Horizontal Pod Autoscaler (HPA) monitorea el uso de CPU/Memoria por microservicio y escala réplicas de pods en segundos (ej. de 2 a 5 pods para `get-products`). Si los nodos se saturan, el Cluster Autoscaler añade instancias EC2 `t4g.small` al Node Group. | Uso eficiente de los recursos cloud, reduciendo el desperdicio financiero y garantizando rendimiento bajo picos imprevistos. |
| **Estrategia de Despliegue y Actualizaciones** | **Con Interrupción (Downtime):** Reemplazar una imagen Docker exige detener el contenedor activo o redirigir puertos manualmente, provocando cortes visibles para el cliente. | **Despliegues Progresivos (Rolling Updates):** Kubernetes levanta los nuevos pods en paralelo, valida que superen el health check y procede a apagar las réplicas antiguas una por una, garantizando **cero tiempo de inactividad**. | Habilita despliegues continuos múltiples veces al día sin degradar la experiencia de usuario ni perder carritos de compra. |
| **Alta Disponibilidad de Base de Datos** | **Vulnerable (SPOF):** La base de datos corre en una sola EC2. Ante un fallo de la AZ o del disco EBS, la empresa queda completamente fuera de línea hasta restaurar un backup (RTO > 4 horas). | **Sincrónica Multi-AZ:** RDS replica cada transacción de forma síncrona a un nodo Standby en una segunda zona (`us-east-1b`). Ante cualquier fallo del nodo primario, se ejecuta un **failover automático en < 60 segundos** sin cambio de DNS ni intervención humana. | Continuidad operativa garantizada: **RPO = 0** (cero pérdida de datos) y **RTO < 60 segundos**. |
| **Mantenimiento y Carga Operativa** | **Alta (60-70% tiempo TI):** El equipo debe parchear el sistema operativo de la BD, actualizar librerías del kernel, crear scripts cron para copias de seguridad y rotar logs manualmente. | **Mínima (< 10% tiempo TI):** AWS administra el mantenimiento del sistema operativo, copias de seguridad automáticas, parches de seguridad del motor MySQL y resiliencia del plano de control EKS. | Reducción drástica del Costo Total de Propiedad (TCO) en horas-hombre, permitiendo al equipo concentrarse en la lógica de negocio. |
| **Observabilidad y Telemetría** | **Básica / Desarticulada:** Métricas generales a nivel de máquina virtual en CloudWatch (CPU, disco de la EC2), sin visibilidad interna de la salud por contenedor. | **Integral con Container Insights:** Métricas detalladas recopiladas por CloudWatch a nivel de nodo, namespace, pod, contenedor y servicio. Permite alertas proactivas antes de que el usuario perciba latencia. | Capacidad de diagnóstico rápido, detección temprana de cuellos de botella y trazabilidad de rendimiento. |
| **Impacto Financiero y TCO** | Costo directo de compute aparentemente menor, pero con un **costo oculto gigantesco** en horas de soporte, riesgo de pérdida de ventas por caída y sobreaprovisionamiento. | Costo mensual de infraestructura ligeramente superior (~$180-$220 USD/mes), pero con un **ahorro neto superior al 45% en TCO global** al evitar caídas comerciales y horas de rescate operativo. | Retorno de inversión altamente positivo que respalda un negocio con crecimiento trimestral del 40%. |

### 2.3. Justificación Técnica de la Evolución hacia EKS y RDS Multi-AZ
La arquitectura tradicional IaaS implementada en la primera fase era adecuada para una etapa temprana de prototipado (*Proof of Concept*), pero resulta inviable para una escala productiva comercial. La transición hacia Amazon EKS y Amazon RDS Multi-AZ se fundamenta técnicamente en los siguientes tres pilares:
1. **Desacoplamiento Estricto y Resiliencia Distribuida:** En la arquitectura previa, un fallo de memoria en el microservicio `create-product` podía agotar los recursos de la máquina virtual y tumbar el microservicio `frontend`, bloqueando la tienda completa. Con EKS, cada microservicio se ejecuta dentro de límites estrictos de recursos (*Requests/Limits* de CPU y RAM) en su propio Pod. Si un proceso satura su cuota o lanza una excepción no controlada, Kubernetes destruye únicamente ese Pod sin afectar al resto del sistema.
2. **Eliminación del Punto Único de Falla en Persistencia:** Las transacciones financieras y el stock del catálogo representan el corazón del negocio de FreshBox. La arquitectura anterior exponía a la empresa a la pérdida irreparable de registros de pedidos ante una catástrofe en la zona `us-east-1a`. Amazon RDS Multi-AZ implementa almacenamiento redundante síncrono a nivel de bloques de disco entre zonas físicas distantes, ofreciendo una garantía de durabilidad del 99.999999999% (11 nueves) y failover instantáneo.
3. **Estandarización de la Industria:** Kubernetes es el estándar de facto a nivel mundial para el despliegue de microservicios. Adoptar Amazon EKS garantiza que los manifiestos, configuraciones y contenedores de FreshBox sean 100% portables, facilitando la futura incorporación de herramientas del ecosistema cloud-native como mallas de servicios (Istio), pipelines de GitOps (ArgoCD) y plataformas de trazabilidad distribuida (OpenTelemetry).

---

## 3. 1.2 ESTRATEGIA DE MODERNIZACIÓN TECNOLÓGICA (IE3.1.2)

### 3.1. Propuesta de Arquitectura Cloud-Native
La propuesta de modernización tecnológica transforma radicalmente la topología de FreshBox SpA, pasando de un enfoque monolítico/artesanal a una arquitectura elástica nativa en la nube estructurada en microservicios contenerizados y servicios PaaS administrados. 

La solución se compone de cuatro subsistemas principales:
1. **Capa Perimetral y de Enrutamiento Elástico (ALB Ingress Controller):**  
   Se implementa un Application Load Balancer en subredes públicas Multi-AZ, gestionado dinámicamente por el *AWS Load Balancer Controller*. Este componente actúa como la puerta de enlace hacia el clúster, recibiendo el tráfico externo seguro por el puerto 80/443 y enrutándolo hacia los pods correspondientes dentro de la red privada.
2. **Capa de Aplicación y Cómputo Orquestado (Amazon EKS + Node Group):**  
   Un clúster Kubernetes administrado (versión 1.30) que orquesta la ejecución de 5 microservicios desacoplados:
   * `frontend`: Interfaz de usuario servida mediante Nginx, configurada como reverse proxy inteligente.
   * `get-products`: API REST en Node.js/Express para consultas de catálogo y detalles de productos (puerto 3001).
   * `create-product`: API REST en Node.js/Express para la creación de nuevos registros en base de datos (puerto 3002).
   * `update-product`: API REST en Node.js/Express para la actualización de stock y metadatos de productos (puerto 3003).
   * `delete-product`: API REST en Node.js/Express para la eliminación de registros del sistema (puerto 3004).  
   Los microservicios corren en un Node Group administrado compuesto por instancias EC2 de arquitectura ARM64 (`t4g.small`), aprovechando los procesadores **AWS Graviton** para maximizar la relación costo-rendimiento y reducir la huella de carbono.
3. **Capa de Persistencia Gestionada (Amazon RDS MySQL Multi-AZ):**  
   Una instancia `db.t4g.small` configurada con almacenamiento gp3 cifrado y alta disponibilidad activa entre dos zonas de disponibilidad, accesible exclusivamente desde los nodos de trabajo de EKS a través del puerto 3306.
4. **Capa de Registro y Observabilidad (Amazon ECR + CloudWatch Container Insights):**  
   Repositorios privados con escaneo de vulnerabilidades automatizado (*Scan on Push*) en Amazon ECR para cada microservicio, y telemetría centralizada con métricas de clúster, nodos y pods en CloudWatch.

### 3.2. Impacto Operacional, Técnico y de Negocio

#### A. Impacto Operacional
* **Reducción del 85% en Horas de Mantenimiento No Planificado:** La eliminación de tareas de parchado de sistemas operativos, instalación de dependencias y reinicios manuales de servicios libera decenas de horas mensuales de los ingenieros de software, las cuales se redirigen a la innovación de la plataforma de ventas.
* **Despliegues Autónomos y Predecibles:** Gracias a los manifiestos declarativos de Kubernetes y el pipeline de GitHub Actions, cualquier cambio de código se compila, prueba y despliega automáticamente a producción mediante despliegues progresivos sin riesgo de cortes en el servicio.
* **Respaldo y Recuperación Simplificada:** Las copias de seguridad de RDS se gestionan de forma nativa sin scripts de cron propensos a fallos, habilitando la recuperación ante desastres a cualquier segundo exacto de los últimos 7 días con un solo clic.

#### B. Impacto Técnico
* **Aislamiento Total de Procesos:** La arquitectura de microservicios en Kubernetes asegura que una falla o degradación en el endpoint de eliminación (`delete-product`) jamás afecte el rendimiento del endpoint de lectura del catálogo (`get-products`), el cual representa más del 80% del tráfico de la tienda.
* **Eficiencia Energética y de Rendimiento con AWS Graviton (ARM64):** La adopción de procesadores Graviton (`t4g.small` tanto en nodos de trabajo EKS como en RDS) entrega hasta un **40% de mejor rendimiento por dólar** en comparación con instancias comparables basadas en arquitecturas x86_64 tradicionales.
* **Seguridad Cero Confianza (*Zero Trust Perimeter*):** Los pods y la base de datos se alojan en subredes privadas sin direcciones IP públicas. La única comunicación entrante permitida hacia los pods proviene del Security Group del Application Load Balancer, y el único tráfico permitido hacia la base de datos proviene del Security Group de los nodos de EKS.

#### C. Impacto de Negocio y Financiero
* **Protección de Ingresos y Reducción del Churn:** Cada minuto de indisponibilidad en un e-commerce en crecimiento genera pérdida de ventas y migración de clientes a la competencia. La garantía de alta disponibilidad (99.95%) y failover transparente en 60 segundos blindan las ventas de la compañía en periodos críticos como CyberMonday, Black Friday o campañas estacionales.
* **Elasticidad Financiera (OPEX Inteligente):** FreshBox ya no requiere pagar por servidores gigantes dimensionados para el peor escenario del año. El autoescalado elástico ajusta la cantidad de pods y nodos en tiempo real, garantizando que la empresa pague únicamente por los recursos que efectivamente consume en cada instante del día.

### 3.3. Alineación con los Objetivos Estratégicos de FreshBox SpA
La estrategia de modernización se alinea de forma impecable con el plan de negocios quinquenal de FreshBox:
1. **Soportar el Crecimiento del 40% Trimestral:** La plataforma actual tiene la capacidad demostrada de duplicar o triplicar su escala de usuarios concurrentes sin necesidad de rediseño arquitectónico.
2. **Velocidad de Time-to-Market:** Los equipos de desarrollo pueden publicar nuevas funcionalidades (ej. pasarelas de pago, suscripciones periódicas de cajas de verduras) de forma independiente y modular sin coordinar despliegues monolíticos masivos.
3. **Gobierno y Cumplimiento Normativo:** El cifrado estricto en reposo y en tránsito protege los datos comerciales y de clientes en estricto cumplimiento con estándares de la industria y la normativa chilena de protección de datos personales.

---

## 4. 1.3 MECANISMOS DE ESCALABILIDAD, SEGURIDAD Y ALTA DISPONIBILIDAD (IE3.2.2)

### 4.1. Elasticidad y Escalabilidad Automática (HPA y Node Groups)
La escalabilidad en la arquitectura TO-BE de FreshBox SpA opera en dos niveles complementarios e integrados:

1. **Horizontal Pod Autoscaler (HPA) a Nivel de Aplicación:**  
   Cada microservicio cuenta con un manifiesto HPA dedicado (`autoscaling/v2`). Los pods tienen definidos de forma estricta sus recursos mínimos requeridos (*requests: 100m CPU, 128Mi RAM*) y sus límites máximos (*limits: 250m CPU, 256Mi RAM*). El algoritmo de autoescalado calcula la utilización promedio de CPU cada 15 segundos mediante la Metrics API. Cuando el consumo promedio supera el **70% de la cuota solicitada**, el HPA calcula y solicita automáticamente la creación de nuevas réplicas:
   $$\text{Réplicas Deseadas} = \left\lceil \text{Réplicas Actuales} \times \left( \frac{\text{Utilización Actual de CPU}}{70\%} \right) \right\rceil$$
   Esto permite que, si una oleada masiva de compras genera sobrecarga en `create-product` o `get-products`, el orquestador escale inmediatamente de 2 a 3, 4 o 5 pods, estabilizando la latencia de respuesta bajo los 200 milisegundos.
2. **Escalamiento Elástico del EKS Node Group:**  
   Para asegurar que el clúster siempre disponga de capacidad física de cómputo para alojar nuevos pods cuando el HPA los cree, el Node Group administrado de EKS está configurado con una política elástica de **mínimo 2 nodos y máximo 4 nodos** distribuidos entre dos zonas de disponibilidad. Si los 2 nodos base alcanzan su capacidad máxima de asignación de CPU o memoria, el Auto Scaling Group de AWS lanza una nueva instancia EC2 `t4g.small`, la une al clúster y programa los pods pendientes en ella sin retraso perceptible.

### 4.2. Seguridad en Profundidad y Segmentación de Red
La arquitectura implementa el principio de **Defensa en Profundidad** (*Defense in Depth*) mediante múltiples capas concéntricas de protección:

* **Segmentación de Red en 3 Capas Aisladas:**  
  La VPC `10.0.0.0/22` se subdivide en 6 subredes con máscara `/25` (128 direcciones IP por subred) distribuidas simétricamente entre `us-east-1a` y `us-east-1b`:
  * Subredes Públicas (`10.0.0.0/25` y `10.0.0.128/25`): Alojan exclusivamente el Application Load Balancer y la pasarela NAT Gateway. Tienen ruta directa al Internet Gateway (`0.0.0.0/0 -> IGW`).
  * Subredes Privadas de Aplicación (`10.0.1.0/25` y `10.0.1.128/25`): Alojan los nodos de cómputo y pods de Amazon EKS. No tienen direcciones IP públicas. Su única salida hacia el exterior se realiza de forma controlada a través de la NAT Gateway.
  * Subredes Privadas de Datos (`10.0.2.0/25` y `10.0.2.128/25`): Alojan las instancias de base de datos Amazon RDS. Están completamente aisladas de Internet, sin pasarela NAT ni rutas de salida externa.
* **Security Groups Encadenados por Mínimo Privilegio:**  
  No se utilizan rangos CIDR abiertos entre capas. Cada Security Group referencia de forma unívoca al Security Group de la capa inmediatamente superior:
  * `freshbox-sg-alb`: Acepta tráfico TCP en los puertos 80 y 443 desde `0.0.0.0/0`.
  * `freshbox-sg-eks-nodes`: Acepta tráfico en el puerto 80 y en el rango 3001-3004 **única y exclusivamente si el origen es el Security Group `freshbox-sg-alb`**. Bloquea cualquier intento de conexión directa desde el exterior.
  * `freshbox-sg-rds`: Acepta conexiones en el puerto 3306 **única y exclusivamente si el paquete proviene de una interfaz asociada al Security Group `freshbox-sg-eks-nodes`**.
* **Cifrado de Datos en Reposo y Gestión Segura de Credenciales:**  
  * Cifrado de Almacenamiento: Todos los volúmenes EBS adjuntos a los nodos de cómputo de EKS y el almacenamiento de base de datos en Amazon RDS están cifrados mediante hardware con el algoritmo estándar de la industria **AES-256** administrado por AWS Key Management Service (AWS KMS).
  * Segregación de Parámetros: Las credenciales críticas (`DB_USER`, `DB_PASS`) nunca se inyectan en texto plano en el código; se administran a través de **Kubernetes Secrets** de tipo `Opaque`. Los parámetros no sensibles (`DB_HOST`, `DB_NAME`, `DB_PORT`) se desacoplan mediante **Kubernetes ConfigMaps**.

### 4.3. Alta Disponibilidad y Resiliencia Multi-AZ
La arquitectura está concebida bajo la filosofía de diseño para el fallo (*Design for Failure*), garantizando que la caída total e intempestiva de un centro de datos completo de AWS no interrumpa la continuidad del negocio:
* **Amazon RDS MySQL Multi-AZ con Réplica Sincrónica:**  
  La base de datos opera con una arquitectura activo-pasivo de alta disponibilidad. La instancia principal procesa lecturas y escrituras en la zona `us-east-1a`, mientras que un servidor Standby idéntico se mantiene sincronizado a nivel de almacenamiento físico en `us-east-1b`. La sincronización es síncrona: una transacción solo se confirma al cliente cuando se ha grabado en ambos discos de ambas zonas. Si la zona primaria sufre una contingencia, AWS ejecuta un **failover automático en menos de 60 segundos**, promoviendo al Standby a primario sin cambio de DNS ni intervención humana.
* **Distribución de Nodos y Cargas de Trabajo Multi-AZ:**  
  Los 2 a 4 nodos de trabajo de EKS se reparten de manera equilibrada entre las zonas de disponibilidad `us-east-1a` y `us-east-1b`. De igual manera, las 2 réplicas mínimas de cada uno de los 5 microservicios (10 pods en total) se distribuyen mediante el programador (*Kubernetes Scheduler*) en nodos de distintas zonas físicas.

---

## 5. DISEÑO DE ARQUITECTURA TO-BE Y FLUJO DE COMUNICACIÓN (IE3.2.1)

### 5.1. Topología de Red en 3 Capas
La arquitectura TO-BE de FreshBox SpA se estructura en 3 niveles de red claramente delimitados:
1. **Capa 1 (Pública):** Aloja el Application Load Balancer y la pasarela NAT Gateway en las subredes públicas Multi-AZ (`10.0.0.0/25` y `10.0.0.128/25`).
2. **Capa 2 (Privada Aplicación):** Aloja el clúster Amazon EKS y su Managed Node Group (2 a 4 instancias `t4g.small`) en subredes privadas (`10.0.1.0/25` y `10.0.1.128/25`).
3. **Capa 3 (Privada Datos):** Aloja la base de datos Amazon RDS MySQL Multi-AZ en subredes privadas de datos (`10.0.2.0/25` y `10.0.2.128/25`).

### 5.2. Flujo de Comunicación End-to-End
1. El usuario accede al nombre DNS del Application Load Balancer vía HTTP/HTTPS.
2. El ALB reenvía el tráfico al Service ClusterIP del Pod `frontend` (Nginx).
3. Nginx evalúa la ruta y método HTTP:
   * `GET /api/products` $ightarrow$ Reenvía a `get-products:3001`.
   * `POST /api/products` $ightarrow$ Reenvía a `create-product:3002`.
   * `PUT /api/products/:id` $ightarrow$ Reenvía a `update-product:3003`.
   * `DELETE /api/products/:id` $ightarrow$ Reenvía a `delete-product:3004`.
4. El microservicio Node.js ejecuta la operación SQL sobre el endpoint de Amazon RDS MySQL Multi-AZ en el puerto 3306.
5. Los datos viajan de retorno al cliente en formato JSON con códigos de respuesta HTTP estándar.

---

## 6. IMPLEMENTACIÓN, MONITOREO Y VALIDACIÓN FUNCIONAL (IE3.3.1 Y IE3.3.2)

### 6.1. Automatización del Despliegue con Terraform y CI/CD
El aprovisionamiento se encuentra completamente codificado:
1. **Compilación ARM64 en GitHub Actions:** Compilación multi-arquitectura con Docker Buildx y push a Amazon ECR.
2. **Infraestructura con Terraform:** Creación de VPC, SGs, RDS Multi-AZ y EKS Cluster.
3. **Despliegue Kubernetes:** Inyección dinámica de variables en ConfigMap/Secret y aplicación de Deployments, Services, Ingress y HPAs.
4. **Poblado de Base de Datos:** Ejecución de `init.sql` mediante un pod efímero de MySQL dentro del clúster.

### 6.2. Estrategia de Validación del Ciclo CRUD
Se comprueban los 4 métodos HTTP vía cURL sobre el ALB DNS:
* `GET /api/products`: Código 200 OK y listado de productos.
* `POST /api/products`: Código 201 Created y confirmación de nuevo registro.
* `PUT /api/products/1`: Código 200 OK y actualización de precio y stock.
* `DELETE /api/products/1`: Código 200 OK y eliminación del registro.

### 6.3. Observabilidad con Amazon CloudWatch Container Insights
Monitoreo continuo de métricas clave (CPUUtilization, MemoryUtilization, PodCount) a nivel de namespace `freshbox`, permitiendo auditar el comportamiento del HPA y detectar cualquier cuello de botella de forma anticipada.

---

## 7. CONCLUSIONES Y RECOMENDACIONES

1. La modernización hacia Amazon EKS y Amazon RDS Multi-AZ proporciona a FreshBox SpA una infraestructura escalable, de alta disponibilidad (99.95%) y con tolerancia a fallos nativa.
2. La eliminación del mantenimiento manual reduce el TCO global en un 45% y permite al equipo TI enfocarse en la estrategia del negocio.
3. El uso de procesadores AWS Graviton (ARM64) maximiza el rendimiento por dólar invertido.

---

## 8. BIBLIOGRAFÍA (NORMATIVA APA v7)

* Amazon Web Services. (2024). *AWS Well-Architected Framework: Reliability, Security and Operational Excellence Pillars*. Amazon Web Services, Inc. https://aws.amazon.com/architecture/well-architected/
* Amazon Web Services. (2024). *Amazon Elastic Kubernetes Service (EKS) User Guide*. AWS Documentation. https://docs.aws.amazon.com/eks/latest/userguide/
* Amazon Web Services. (2024). *Amazon Relational Database Service (RDS) Multi-AZ Deployments*. AWS Documentation. https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html
* Kubernetes Authors. (2024). *Horizontal Pod Autoscaling Documentation*. Kubernetes Documentation. https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
* Pastenet, I. A. (2026). *Guía Didáctica de Implementación: Orquestación de Contenedores y Servicios PaaS (ARY1102)*. Escuela de Informática y Telecomunicaciones, DuocUC.
