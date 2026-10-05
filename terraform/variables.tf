variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto para nomenclatura de recursos"
  type        = string
  default     = "freshbox"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/22"
}

variable "public_subnet_cidrs" {
  description = "CIDRs para subredes publicas (Web/ALB)"
  type        = list(string)
  default     = ["10.0.0.0/26", "10.0.0.64/26"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDRs para subredes privadas APP (ECS Fargate)"
  type        = list(string)
  default     = ["10.0.1.0/26", "10.0.1.64/26"]
}

variable "private_data_subnet_cidrs" {
  description = "CIDRs para subredes privadas DATA (MySQL)"
  type        = list(string)
  default     = ["10.0.2.0/26", "10.0.2.64/26"]
}

variable "db_user" {
  description = "Usuario de la base de datos MySQL"
  type        = string
  default     = "alumno"
}

variable "db_password" {
  description = "Password de la base de datos MySQL"
  type        = string
  default     = "alumno123"
  sensitive   = true
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "freshbox"
}

variable "ec2_instance_type" {
  description = "Tipo de instancia EC2 para MySQL"
  type        = string
  default     = "t3.small"
}

variable "ecs_task_cpu" {
  description = "CPU units para el ECS Task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "ecs_task_memory" {
  description = "Memoria en MB para el ECS Task"
  type        = number
  default     = 2048
}

variable "ecs_desired_count" {
  description = "Numero deseado de ECS tasks (Multi-AZ)"
  type        = number
  default     = 2
}

variable "ecr_image_tag" {
  description = "Tag de las imagenes Docker en ECR"
  type        = string
  default     = "latest"
}

# -----------------------------------------------------------------------------
# Auto Scaling para Contenedores ECS Fargate
# -----------------------------------------------------------------------------
variable "ecs_min_capacity" {
  description = "Capacidad minima de tareas/contenedores para el Auto Scaling (Multi-AZ)"
  type        = number
  default     = 2
}

variable "ecs_max_capacity" {
  description = "Capacidad maxima de tareas/contenedores para el Auto Scaling"
  type        = number
  default     = 4
}

variable "asg_cpu_target_value" {
  description = "Porcentaje objetivo de utilizacion promedio de CPU para escalar los contenedores"
  type        = number
  default     = 70.0
}

variable "asg_memory_target_value" {
  description = "Porcentaje objetivo de utilizacion promedio de memoria RAM para escalar los contenedores"
  type        = number
  default     = 80.0
}

# -----------------------------------------------------------------------------
# Sistema de Etiquetado FinOps para Cost Explorer y AWS Budgets
# -----------------------------------------------------------------------------
variable "environment" {
  description = "Ambiente de despliegue de la infraestructura"
  type        = string
  default     = "production"
}

variable "common_tags" {
  description = "Etiquetas estándar corporativas aplicables para asignacion de costos en Cost Explorer y AWS Budgets"
  type        = map(string)
  default = {
    Project       = "freshbox"
    Environment   = "production"
    ManagedBy     = "terraform"
    CostCenter    = "CC-102-ECOMMERCE"
    Owner         = "DevOps-FreshBox"
    Application   = "freshbox-catalog"
    BusinessUnit  = "Retail-Organico"
    TerraformRepo = "freshbox-cloud-architecture"
  }
}

# -----------------------------------------------------------------------------
# AWS Budgets en Código
# -----------------------------------------------------------------------------
variable "enable_aws_budget" {
  description = "Habilitar la creacion de alertas de presupuesto con AWS Budgets"
  type        = bool
  default     = true
}

variable "monthly_budget_limit" {
  description = "Limite mensual en USD para el presupuesto global de FreshBox SpA"
  type        = string
  default     = "150"
}

variable "containers_budget_limit" {
  description = "Limite mensual en USD para la capa especifica de computo/contenedores"
  type        = string
  default     = "80"
}

variable "budget_notification_email" {
  description = "Correo electronico que recibira las notificaciones y alertas de presupuesto de AWS Budgets"
  type        = string
  default     = "gaston.mardones@duocuc.cl"
}

