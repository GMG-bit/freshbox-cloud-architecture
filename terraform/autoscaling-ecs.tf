# =============================================================================
# Auto Scaling para Contenedores ECS Fargate (FreshBox SpA)
# =============================================================================
# Gestiona la elasticidad automatica de la flota de tareas/contenedores
# cumpliendo con el rango de escalamiento: Minimo 2, Maximo 4 tareas Multi-AZ.
# =============================================================================

# 1. Definicion del Target de Auto Scaling para el servicio ECS
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.ecs_max_capacity
  min_capacity       = var.ecs_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    Name        = "${var.project_name}-appautoscaling-target"
    Component   = "containers-autoscaling"
    AutoScaling = "enabled"
  }
}

# 2. Politica de Escalamiento basada en Utilizacion Promedio de CPU (Target Tracking)
resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.project_name}-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.asg_cpu_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# 3. Politica de Escalamiento basada en Utilizacion Promedio de Memoria RAM (Target Tracking)
resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.project_name}-memory-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.asg_memory_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# 4. Alarmas CloudWatch para Observabilidad y Monitoreo del Escalamiento
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-containers-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.asg_cpu_target_value
  alarm_description   = "Alarma activada cuando el uso promedio de CPU de los contenedores supera el ${var.asg_cpu_target_value}%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  tags = {
    Name      = "${var.project_name}-alarm-cpu-high"
    Component = "containers-monitoring"
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.project_name}-containers-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.asg_memory_target_value
  alarm_description   = "Alarma activada cuando el uso promedio de RAM de los contenedores supera el ${var.asg_memory_target_value}%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  tags = {
    Name      = "${var.project_name}-alarm-memory-high"
    Component = "containers-monitoring"
  }
}
