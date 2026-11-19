variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto"
  type        = string
  default     = "freshbox"
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para el carrito"
  type        = string
  default     = "carrito-freshbox"
}

variable "sqs_queue_name" {
  description = "Nombre de la cola SQS para procesamiento de ordenes"
  type        = string
  default     = "ordenes-freshbox"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "prod"
}

variable "eks_alb_dns_name" {
  description = "DNS o IP del Application Load Balancer de EKS para enrutamiento del catalogo CRUD"
  type        = string
  default     = "http://localhost:3000"
}

variable "vpc_id" {
  description = "ID de la VPC existente para VPC Endpoints y Lambda en VPC"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Subredes privadas para ejecucion de Lambda order-process (acceso a RDS)"
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "Security groups para Lambdas dentro de la VPC"
  type        = list(string)
  default     = []
}

variable "db_host" {
  description = "Endpoint de conexion de Amazon RDS MySQL Multi-AZ"
  type        = string
  default     = "localhost"
}

variable "db_user" {
  description = "Usuario de la base de datos MySQL"
  type        = string
  default     = "alumno"
}

variable "db_password" {
  description = "Contrasena de la base de datos MySQL"
  type        = string
  default     = "alumno123"
  sensitive   = true
}

variable "db_name" {
  description = "Nombre de la base de datos MySQL"
  type        = string
  default     = "freshbox"
}

variable "db_port" {
  description = "Puerto de conexion de la base de datos MySQL"
  type        = string
  default     = "3306"
}
