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

# -----------------------------------------------------------------------------
# Outputs de Auto Scaling para Contenedores
# -----------------------------------------------------------------------------
output "autoscaling_target_id" {
  description = "ID del target de Auto Scaling del servicio ECS"
  value       = aws_appautoscaling_target.ecs.id
}

output "autoscaling_cpu_policy_arn" {
  description = "ARN de la politica de auto scaling por CPU"
  value       = aws_appautoscaling_policy.cpu.arn
}

output "autoscaling_memory_policy_arn" {
  description = "ARN de la politica de auto scaling por memoria"
  value       = aws_appautoscaling_policy.memory.arn
}

output "autoscaling_capacity_range" {
  description = "Rango de escalamiento de tareas/contenedores (Min - Max)"
  value = {
    min_capacity = aws_appautoscaling_target.ecs.min_capacity
    max_capacity = aws_appautoscaling_target.ecs.max_capacity
  }
}

# -----------------------------------------------------------------------------
# Outputs del Sistema de Etiquetado y FinOps
# -----------------------------------------------------------------------------
output "common_tags" {
  description = "Etiquetas comunes aplicadas para asignacion de costos en Cost Explorer y Budgets"
  value       = var.common_tags
}

output "cost_allocation_keys" {
  description = "Claves de etiquetas recomendadas para activar en AWS Cost Allocation Tags"
  value = [
    "Project",
    "Environment",
    "CostCenter",
    "Component",
    "Application",
    "Owner"
  ]
}

output "budgets_configured" {
  description = "Detalle de los presupuestos configurados en AWS Budgets"
  value = var.enable_aws_budget ? {
    global_budget_name     = aws_budgets_budget.freshbox_global[0].name
    global_budget_limit    = "${aws_budgets_budget.freshbox_global[0].limit_amount} ${aws_budgets_budget.freshbox_global[0].limit_unit}"
    containers_budget_name = aws_budgets_budget.freshbox_containers[0].name
    notification_recipient = var.budget_notification_email
  } : null
}

