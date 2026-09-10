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
