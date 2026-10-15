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
  description = "CIDRs para subredes publicas (ALB Ingress / NAT Gateway)"
  type        = list(string)
  default     = ["10.0.0.0/25", "10.0.0.128/25"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDRs para subredes privadas APP (EKS Worker Nodes / Pods)"
  type        = list(string)
  default     = ["10.0.1.0/25", "10.0.1.128/25"]
}

variable "private_data_subnet_cidrs" {
  description = "CIDRs para subredes privadas DATA (RDS MySQL Multi-AZ)"
  type        = list(string)
  default     = ["10.0.2.0/25", "10.0.2.128/25"]
}

# -----------------------------------------
# Variables Amazon EKS (Kubernetes)
# -----------------------------------------
variable "eks_version" {
  description = "Version de Kubernetes para el cluster EKS"
  type        = string
  default     = "1.30"
}

variable "eks_node_instance_type" {
  description = "Tipo de instancia EC2 para los worker nodes del EKS Node Group"
  type        = string
  default     = "t4g.small"
}

variable "eks_ami_type" {
  description = "Tipo de AMI para los worker nodes del EKS Node Group (ARM64 para t4g)"
  type        = string
  default     = "AL2023_ARM_64_STANDARD"
}

variable "eks_node_desired_size" {
  description = "Cantidad deseada de worker nodes en el cluster EKS"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Cantidad minima de worker nodes en el cluster EKS"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Cantidad maxima de worker nodes en el cluster EKS (escalabilidad)"
  type        = number
  default     = 4
}

# -----------------------------------------
# Variables Amazon RDS MySQL Multi-AZ
# -----------------------------------------
variable "db_instance_class" {
  description = "Clase de instancia para la base de datos RDS MySQL Multi-AZ"
  type        = string
  default     = "db.t4g.small"
}

variable "db_user" {
  description = "Usuario administrador de la base de datos MySQL"
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

# -----------------------------------------
# Variables ECR y FinOps (AWS Budgets)
# -----------------------------------------
variable "ecr_image_tag" {
  description = "Tag de las imagenes Docker en ECR"
  type        = string
  default     = "latest"
}

variable "enable_aws_budget" {
  description = "Habilitar la creacion de presupuestos en AWS Budgets"
  type        = bool
  default     = false
}

variable "monthly_budget_limit" {
  description = "Limite del presupuesto mensual global en USD para AWS Budgets"
  type        = string
  default     = "50"
}

variable "containers_budget_limit" {
  description = "Limite del presupuesto para computo de contenedores en USD"
  type        = string
  default     = "25"
}

variable "budget_notification_email" {
  description = "Email para recibir alertas de presupuesto"
  type        = string
  default     = "alertas-cloud@freshbox.cl"
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "freshbox"
    CostCenter  = "CC-TI-CLOUD"
    Course      = "ARY1102-Arquitectura-Cloud"
    Activity    = "EA2-EKS-RDS-MultiAZ"
  }
}
