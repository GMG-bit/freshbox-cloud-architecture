output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL del Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_urls" {
  description = "URLs de los repositorios ECR"
  value = {
    frontend       = data.aws_ecr_repository.repos["frontend"].repository_url
    get_products   = data.aws_ecr_repository.repos["get-products"].repository_url
    create_product = data.aws_ecr_repository.repos["create-product"].repository_url
    update_product = data.aws_ecr_repository.repos["update-product"].repository_url
    delete_product = data.aws_ecr_repository.repos["delete-product"].repository_url
  }
}

output "mysql_private_ip" {
  description = "IP privada del EC2 MySQL"
  value       = aws_instance.mysql.private_ip
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.main.name
}
