# Informe Técnico — EP1: FreshBox SpA
## Arquitectura Cloud (ARY1102) — DuocUC 2026

### Índice
1. [Introducción](#introducción)
2. [1.1 Fundamentación del Rol del Arquitecto Cloud](#11-fundamentación-del-rol-del-arquitecto-cloud)
3. [1.2 Pilares del Well-Architected Framework](#12-pilares-del-well-architected-framework)
4. [1.3 Análisis de Arquitectura según Well-Architected](#13-análisis-de-arquitectura-según-well-architected)
5. [1.4 Priorización de Requerimientos](#14-priorización-de-requerimientos)
6. [1.5 Comparación de Modelos de Nube](#15-comparación-de-modelos-de-nube)
7. [1.6 Justificación del Modelo Cloud](#16-justificación-del-modelo-cloud)
8. [1.7 Validación del Diseño](#17-validación-del-diseño)
9. [Conclusiones](#conclusiones)
10. [Bibliografía](#bibliografía)

---

### Introducción

FreshBox SpA es una compañía de comercio electrónico que se ha consolidado rápidamente en el mercado de la venta de productos orgánicos. Actualmente, la organización está experimentando un crecimiento trimestral acelerado del 40%, lo que ha llevado sus sistemas tradicionales (on-premise/monolíticos) al límite de su capacidad operativa. Ante la necesidad urgente de modernizar su plataforma para garantizar la escalabilidad, la disponibilidad y la seguridad, se hace imperativo el diseño e implementación de una arquitectura nativa en la nube. 

Este informe técnico detalla el diseño de la nueva infraestructura en Amazon Web Services (AWS) propuesta para FreshBox SpA. A través de este documento, se aborda la justificación estratégica y técnica de las decisiones arquitectónicas, sustentadas en el rol del Arquitecto Cloud, los principios del AWS Well-Architected Framework, y el análisis de modelos de nube. Se propone una arquitectura basada en microservicios utilizando contenedores orquestados por ECS Fargate, infraestructura como código con Terraform, y despliegues automatizados mediante GitHub Actions, permitiendo así una transición exitosa hacia una operación ágil, elástica y alineada con los objetivos de negocio de la empresa.

---

### 1.1 Fundamentación del Rol del Arquitecto Cloud

El rol del Arquitecto Cloud es fundamental en el panorama tecnológico actual. Se define como el puente estratégico entre las necesidades del negocio y las soluciones tecnológicas en la nube. Un Arquitecto Cloud no solo diseña sistemas; su objetivo primordial es concebir plataformas altamente escalables, resilientes y eficientes que habiliten la innovación y resuelvan problemas empresariales complejos.

**Responsabilidades Técnicas:**
Desde una perspectiva técnica, el Arquitecto Cloud es responsable de:
- **Selección de Servicios:** Identificar y elegir los componentes cloud más adecuados (ej. contenedores vs máquinas virtuales, bases de datos SQL vs NoSQL).
- **Diseño de Arquitectura:** Estructurar la red (VPC, subnets), el flujo de datos y la integración de sistemas para garantizar un acoplamiento débil.
- **Seguridad:** Establecer perímetros de defensa, políticas de acceso (IAM), cifrado de datos y aislamiento de red.
- **Optimización de Costos y Rendimiento:** Asegurar que los recursos estén correctamente dimensionados (right-sizing) y se utilicen de manera económicamente viable.
- **Recuperación ante Desastres (DR):** Definir estrategias de backup, RTO (Recovery Time Objective) y RPO (Recovery Point Objective) para mantener la continuidad operativa.

**Responsabilidades Estratégicas:**
En el nivel de negocio, sus responsabilidades incluyen:
- **Alineación:** Asegurar que la tecnología adoptada soporte los objetivos comerciales a corto y largo plazo.
- **Transformación Digital:** Guiar a la organización en el cambio cultural y operativo hacia metodologías DevOps y agilidad.
- **Habilitación de Innovación:** Proveer plataformas que permitan iterar rápidamente, lanzar nuevos productos al mercado con menor fricción y reducir el *time to market*.

**Alineación con FreshBox SpA:**
Dado el crecimiento sostenido del 40% trimestral de FreshBox, una arquitectura estática es inviable. El diseño propuesto se alinea con este desafío de la siguiente manera:
- **Arquitectura Elástica:** Soporta el aumento de tráfico sin degradación del servicio.
- **Serverless (ECS Fargate):** Elimina la sobrecarga de administración de servidores físicos o virtuales (patching del SO), permitiendo al equipo concentrarse en el desarrollo de valor.
- **Terraform (IaC):** Proporciona infraestructura reproducible, versionada y auditable, reduciendo errores manuales.
- **Orquestación de Contenedores:** Habilita despliegues rápidos y consistentes en múltiples entornos.

**¿Por qué ECS Fargate sobre EC2 + Docker?**
La decisión de utilizar AWS Fargate en lugar de instancias EC2 autogestionadas con Docker se fundamenta en la madurez operativa que se busca para FreshBox. Fargate abstrae la capa de infraestructura, lo que significa cero parches de sistemas operativos y un escalamiento automático nativo basado en la demanda real. Además, adopta un modelo financiero de pago por uso (pay-per-use), donde solo se factura por los recursos de cómputo (vCPU y RAM) consumidos por los contenedores, optimizando los costos frente a la alternativa de mantener instancias EC2 ociosas.

---

### 1.2 Pilares del Well-Architected Framework

El diseño de la arquitectura para FreshBox se ha fundamentado estrictamente en los 6 pilares del AWS Well-Architected Framework:

1. **Excelencia Operacional:**
   Se ha diseñado para automatizar y simplificar las operaciones. Amazon ECS gestiona de forma autónoma el ciclo de vida de los contenedores, realizando *health checks* y *rolling updates* sin tiempo de inactividad. La infraestructura completa se maneja a través de código (Terraform), asegurando consistencia y despliegues predecibles. Además, la integración continua y el despliegue continuo (CI/CD) están automatizados con GitHub Actions, reduciendo la intervención humana. CloudWatch Logs proporciona la observabilidad centralizada necesaria para la resolución rápida de incidentes.

2. **Seguridad:**
   La arquitectura emplea una estrategia de defensa en profundidad. Se han implementado Grupos de Seguridad (Security Groups) segmentados por capa: el tráfico fluye del ALB al APP (ECS) y luego al DATA (EC2 MySQL), evitando el acceso directo entre capas no adyacentes. Se utiliza cifrado de volúmenes EBS para proteger los datos en reposo, y ECR realiza escaneos automáticos de vulnerabilidades en las imágenes Docker. Los contenedores y la base de datos residen en subredes privadas, sin acceso directo a Internet, cumpliendo con el principio de mínimo privilegio.

3. **Confiabilidad:**
   La solución está diseñada para recuperarse automáticamente de fallos. El Application Load Balancer (ALB) distribuye el tráfico a través de múltiples Zonas de Disponibilidad (Multi-AZ). ECS mantiene la confiabilidad al reiniciar automáticamente cualquier tarea fallida, manteniendo un *desired_count=2* para asegurar la redundancia de los microservicios. Para la capa de datos, se ha integrado AWS Backup, garantizando copias de seguridad automatizadas de la base de datos MySQL para asegurar la recuperación ante desastres (DR).

4. **Eficiencia de Rendimiento:**
   Los recursos informáticos están altamente optimizados. Fargate escala las tareas de forma independiente según la carga de trabajo. Cada microservicio contenedorizado está dimensionado precisamente para sus necesidades (*right-sized* con 0.25 vCPU y 0.5 GB de RAM) utilizando arquitectura x86_64. El ALB asegura que las solicitudes se distribuyan de manera eficiente, evitando la sobrecarga en un único contenedor.

5. **Optimización de Costos:**
   El modelo *Serverless* de Fargate es intrínsecamente amigable con el presupuesto. Se pasa de un modelo de gastos de capital (CAPEX) a uno de gastos operativos (OPEX). Al pagar exclusivamente por el tiempo de cómputo consumido por tarea, se elimina el costo por instancias EC2 ociosas en la capa de aplicación. El costo mensual estimado de la solución se mantiene controlado entre $80 y $120 USD, alineado con las posibilidades de una startup en fase de crecimiento.

6. **Sostenibilidad:**
   La arquitectura maximiza la utilización de recursos y minimiza el impacto ambiental. Al utilizar contenedores y Fargate, no existen servidores inactivos consumiendo energía innecesariamente, ya que los recursos solo se aprovisionan y consumen durante la ejecución real de las tareas.

---

### 1.3 Análisis de Arquitectura según Well-Architected

A continuación, se identifican riesgos iniciales y oportunidades de mejora basadas en las mejores prácticas de la nube:

| Pilar | Riesgo Identificado | Oportunidad de Mejora | Recomendación |
| :--- | :--- | :--- | :--- |
| **Excelencia Operacional** | Despliegues manuales de aplicaciones que propician errores. | Implementar automatización total del pipeline. | **Implementar GitHub Actions (✓ Aplicado en el diseño actual).** |
| **Seguridad** | Credenciales de DB expuestas en texto plano como variables de entorno. | Centralizar la gestión de secretos. | Utilizar AWS Secrets Manager o Parameter Store (Fase 2). |
| **Confiabilidad** | Base de datos MySQL alojada en una única instancia EC2 (Punto único de fallo - SPOF). | Desacoplar y añadir redundancia a la persistencia de datos. | Migrar a Amazon RDS Multi-AZ (Fase 2). |
| **Eficiencia de Rendimiento** | Contenido estático servido directamente desde los contenedores Nginx. | Reducir latencia global y liberar cómputo. | Implementar Amazon CloudFront junto con Amazon S3 (Fase 2). |
| **Optimización de Costos** | Altos costos por el procesamiento de datos del NAT Gateway ($0.045/hr) al descargar imágenes. | Evitar el tránsito de datos por internet para servicios internos de AWS. | Configurar VPC Endpoints para ECR, CloudWatch y S3 (Fase 2). |
| **Sostenibilidad** | Imágenes Docker pesadas que aumentan tiempos de descarga y consumo de red. | Optimizar el empaquetado de aplicaciones. | Implementar Multi-stage builds y usar bases Alpine **(✓ Aplicado).** |

---

### 1.4 Priorización de Requerimientos

El éxito del proyecto radica en alinear la tecnología con las necesidades reales y urgentes del negocio.

| ID | Requerimiento | Tipo | Prioridad | Justificación |
| :--- | :--- | :--- | :--- | :--- |
| **RF01** | Operaciones CRUD para el catálogo de productos. | Funcional | Alta | Funcionalidad core del e-commerce. Sin ella, no hay negocio. Habilitado por las APIs Node.js y MySQL. |
| **RF02** | Visualización de un catálogo público de productos orgánicos. | Funcional | Alta | Punto de entrada para los clientes de FreshBox. Soportado por el frontend Nginx y la API GET. |
| **RF03** | Panel de administración de inventario y productos. | Funcional | Alta | Requerido por el equipo interno para gestionar la oferta (APIs POST, PUT, DELETE). |
| **RNF01** | Alta Disponibilidad del 99.9% frente a fallos. | No Funcional | Alta | Las caídas de servicio implican pérdida directa de ventas. Mitigado mediante ALB Multi-AZ y redundancia en ECS. |
| **RNF02** | Escalabilidad automática para soportar el crecimiento del 40%. | No Funcional | Alta | El crecimiento trimestral saturaría servidores estáticos. Soportado dinámicamente por la elasticidad de ECS Fargate. |
| **RNF03** | Seguridad perimetral estructurada por capas (N-Tier). | No Funcional | Alta | Proteger la información de la empresa y clientes es crítico. Abordado mediante subredes privadas y SGs encadenados. |
| **RNF04** | Tiempos de respuesta para el usuario menores a 2 segundos. | No Funcional | Media | Crucial para la retención de clientes en e-commerce. Logrado gracias al bajo acoplamiento de microservicios y red local rápida en VPC. |
| **RNF05** | Copias de seguridad y estrategia Disaster Recovery (DR). | No Funcional | Media | Resguardo del capital de datos ante corrupción accidental o maliciosa. Cubierto por políticas de AWS Backup. |
| **RNF06** | Cifrado de datos en reposo y tránsito. | No Funcional | Media | Cumplimiento de normativas de seguridad de datos. Solucionado mediante certificados en ALB (tránsito) y EBS Encryption (reposo). |
| **RNF07** | Monitoreo centralizado y generación de alertas. | No Funcional | Baja | Necesario para mantenimiento proactivo, pero no bloqueante en Fase 1. Se cubren las bases con CloudWatch. |
| **RNF08** | Canalización CI/CD totalmente automatizada. | No Funcional | Media | Agiliza entregas de código y reduce *downtime* por errores. Implementado mediante flujos de GitHub Actions. |
| **RNF09** | Infraestructura como Código (IaC) auditable y reproducible. | No Funcional | Media | Permite recuperación completa del entorno y replicación en ambientes (Dev/QA/Prod). Soportado íntegramente por Terraform. |

---

### 1.5 Comparación de Modelos de Nube

Para sustentar la elección tecnológica, se analizaron los tres principales modelos de computación en la nube:

| Característica | Nube Pública (AWS, Azure) | Nube Privada (On-Premise) | Nube Híbrida |
| :--- | :--- | :--- | :--- |
| **Estructura de Costos Iniciales** | **OPEX** (Gasto Operativo). Pago por consumo, cero inversión inicial en hardware. | **CAPEX** (Gasto de Capital). Alta inversión inicial en servidores físicos, climatización y red. | Combinación de altos costos iniciales y costos variables por recursos extendidos. |
| **Escalabilidad y Elasticidad** | Prácticamente ilimitada e instantánea en minutos. | Limitada por la capacidad física del hardware adquirido. Lenta expansión. | Escalabilidad elástica hacia la nube pública durante picos de demanda (Cloud Bursting). |
| **Seguridad y Cumplimiento** | Compartida (Shared Responsibility). El proveedor asegura la infraestructura; el cliente, los datos. | Control físico total, pero recae 100% la responsabilidad de actualizaciones y parches en el cliente. | Alta complejidad en la gestión de políticas y redes unificadas entre entornos. |
| **Disponibilidad / Resiliencia** | Alta, con opciones Multi-Región y Multi-AZ provistas nativamente. | Requiere inversión masiva para crear redundancia geográfica (Data Centers secundarios). | Permite alta resiliencia si se diseña correctamente, asumiendo grandes costos. |
| **Tiempo de Salida al Mercado (Time to Market)** | **Muy Rápido** (horas/días). Los servicios están preconfigurados y listos para su aprovisionamiento. | Lento (semanas/meses). Requiere compra, entrega, instalación y configuración física. | Medio. Depende de la velocidad de integración de los entornos legados y modernos. |
| **Soporte de Contenedores y Serverless** | Nativo, robusto, gestionado y altamente integrado (ej. ECS Fargate, EKS, Lambda). | Requiere instalación y gestión de orquestadores complejos como Kubernetes o Docker Swarm desde cero. | Gestión segmentada, a menudo requiere plataformas como Red Hat OpenShift o Anthos. |
| **Adecuación para FreshBox SpA (Startup)** | **Óptima.** Ideal para su crecimiento acelerado (40%) y su carencia de capital para construir centros de datos. | Inviable. Estrangularía la liquidez de la empresa y limitaría su crecimiento operativo. | Innecesariamente compleja. No hay sistemas legados críticos que obliguen a retener hardware físico. |

---

### 1.6 Justificación del Modelo Cloud

Con base en el análisis previo, se ha seleccionado el modelo de **Nube Pública**, específicamente AWS (Amazon Web Services).

**Justificación Técnica:**
El uso de la Nube Pública permite a FreshBox aprovechar tecnologías avanzadas desde el primer día sin esfuerzo de instalación. ECS Fargate proporciona una orquestación de contenedores Serverless que abstrae el sistema operativo, simplificando drásticamente la operativa. La arquitectura Multi-AZ, que en un modelo *on-premise* costaría cientos de miles de dólares, viene de forma nativa en AWS. Además, la profunda integración entre servicios de red (VPC, ALB), almacenamiento (ECR), observabilidad (CloudWatch) y el robusto soporte para Terraform, aseguran que la plataforma sea técnica e inherentemente superior.

**Justificación Financiera:**
Para una empresa en fase de crecimiento sostenido, inmovilizar capital en servidores físicos es un riesgo financiero innecesario. El modelo OPEX (Gasto Operativo) de la Nube Pública es el adecuado. El esquema de precios de Fargate es por tarea, es decir, FreshBox paga aproximadamente $0.04 USD por hora por cada vCPU y unos centavos por GB de RAM, pero *solo* mientras el contenedor está ejecutándose. Esto erradica el coste de tener instancias informáticas subutilizadas durante las horas nocturnas o valles de demanda. El costo total de propiedad (TCO) de esta arquitectura se estima en unos conservadores $80 a $120 mensuales en su fase inicial.

**Justificación Estratégica:**
El negocio de FreshBox es vender productos orgánicos, no administrar centros de datos. Al delegar la capa de infraestructura física y virtualización a AWS, el equipo de ingeniería puede concentrarse en el desarrollo del producto y mejoras a la experiencia de usuario (generando valor de negocio directo). Adicionalmente, el crecimiento del 40% trimestral requiere una plataforma que no sea un cuello de botella; la elasticidad de AWS asegura que el crecimiento del negocio esté tecnológicamente habilitado y asegurado, facilitando un *Time to Market* inigualable.

---

### 1.7 Validación del Diseño

El diseño de arquitectura propuesto cumple rigurosamente con los requisitos evaluados:

| Atributo / Requerimiento | Validación en el Diseño |
| :--- | :--- |
| **Alta Disponibilidad** | Soportada por el aprovisionamiento de subredes públicas y privadas en múltiples Zonas de Disponibilidad (Multi-AZ). El ALB enruta tráfico solo hacia las instancias/tareas sanas. AWS Backup toma instantáneas periódicas para asegurar el RPO. |
| **Escalabilidad** | Totalmente resuelto en la capa de aplicación con ECS. Es posible incrementar el `desired_count` de las tareas mediante IaC o consola, y AWS Fargate aprovisiona el cómputo necesario bajo demanda de manera dinámica. En futuras iteraciones se implementará un Application Autoscaling (HPA). |
| **Buenas Prácticas (Seguridad)** | Aplicadas mediante el patrón de diseño "Defense in Depth". Se utilizan Security Groups estrictamente limitados (ALB → APP → DB). Las bases de datos y la lógica de negocio residen en subredes sin IP públicas ni acceso directo desde el exterior, cumpliendo el principio de menor privilegio. |
| **Buenas Prácticas (Operaciones)** | La infraestructura se define completamente con Terraform, garantizando control de versiones y auditoría de cambios. Los despliegues de aplicaciones se manejan sin fricción a través de integración continua (CI) en GitHub Actions y ECR. |

---

### Conclusiones

La arquitectura diseñada e implementada para FreshBox SpA representa una modernización completa y robusta de sus sistemas, alineada estrechamente con sus imperativos comerciales. Mediante la adopción de un modelo Cloud Native en AWS, utilizando Amazon ECS Fargate, la organización ahora dispone de un entorno altamente elástico que puede soportar sin contratiempos su crecimiento sostenido del 40% trimestral.

La decisión de utilizar la infraestructura como código (IaC) a través de Terraform asegura que los entornos de la empresa sean auditables, replicables y libres de configuraciones manuales propensas a errores. Al combinar esto con las canalizaciones automatizadas de GitHub Actions, FreshBox ha madurado operativamente hacia prácticas DevOps modernas, acelerando su tiempo de entrega de software y mejorando la confiabilidad de sus despliegues.

Aunque la solución actual cumple de manera excelente con todos los requerimientos funcionales y no funcionales de la Fase 1, se han identificado claramente las mejoras para futuras iteraciones, tales como la migración de la base de datos a Amazon RDS Multi-AZ, la integración de Amazon CloudFront para distribución de contenido estático y la adopción de AWS Secrets Manager para optimizar aún más la postura de seguridad. En definitiva, FreshBox SpA cuenta ahora con una base tecnológica preparada para escalar y liderar el comercio electrónico orgánico con confianza.

---

### Bibliografía

* Amazon Web Services. (2024). *AWS Well-Architected Framework*. Recuperado de https://aws.amazon.com/architecture/well-architected/
* Amazon Web Services. (2024). *Amazon Elastic Container Service (ECS) Documentation*. Recuperado de https://docs.aws.amazon.com/ecs/
* Amazon Web Services. (2024). *AWS Fargate Documentation*. Recuperado de https://docs.aws.amazon.com/ecs/latest/developerguide/AWS_Fargate.html
* HashiCorp. (2024). *Terraform AWS Provider Documentation*. Recuperado de https://registry.terraform.io/providers/hashicorp/aws/latest/docs
* Docker Inc. (2024). *Docker Documentation: Best practices for writing Dockerfiles*. Recuperado de https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
