# ==============================================================================
# Outputs de Infraestructura Cloud - EA2 (EKS + RDS Multi-AZ)
# ==============================================================================

# VPC y Red
output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs de las subredes publicas (ALB Ingress / NAT Gateway)"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs de las subredes privadas de Aplicacion (EKS Worker Nodes)"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "IDs de las subredes privadas de Datos (RDS MySQL Multi-AZ)"
  value       = aws_subnet.private_data[*].id
}

output "nat_gateway_ip" {
  description = "IP elastica publica del NAT Gateway"
  value       = aws_eip.nat.public_ip
}

# Amazon EKS (Kubernetes)
output "eks_cluster_name" {
  description = "Nombre del cluster Amazon EKS"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint de la API del cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_arn" {
  description = "ARN del cluster EKS"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_version" {
  description = "Version de Kubernetes del cluster"
  value       = aws_eks_cluster.main.version
}

output "eks_node_group_name" {
  description = "Nombre del Node Group administrado de EKS"
  value       = aws_eks_node_group.main.node_group_name
}

output "eks_node_group_status" {
  description = "Estado del Node Group de EKS"
  value       = aws_eks_node_group.main.status
}

# Amazon RDS MySQL Multi-AZ
output "rds_endpoint" {
  description = "Endpoint de conexion a la base de datos RDS MySQL Multi-AZ"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Direccion DNS del host de la base de datos RDS MySQL"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Puerto de conexion a MySQL"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "Nombre de la base de datos creada en RDS"
  value       = aws_db_instance.main.db_name
}

output "rds_multi_az" {
  description = "Indica si RDS esta configurado en Multi-AZ"
  value       = aws_db_instance.main.multi_az
}

# Amazon ECR
output "ecr_repository_urls" {
  description = "URLs de los repositorios ECR para cada microservicio"
  value       = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}

# Comandos de ayuda inmediata para el estudiante
output "kubeconfig_command" {
  description = "Comando para configurar kubectl con el cluster EKS"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "instruction_next_steps" {
  description = "Pasos para desplegar la aplicacion en EKS"
  value       = "1. Ejecuta: aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name} | 2. Sube las imagenes con scripts/build-and-push.sh | 3. Aplica los manifiestos con: kubectl apply -f k8s/"
}
