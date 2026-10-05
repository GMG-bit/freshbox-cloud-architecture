# =============================================================================
# AWS Budgets en Código — Gobernanza Financiera y FinOps (FreshBox SpA)
# =============================================================================
# Implementa presupuestos y alertas automatizadas vinculadas al sistema
# de etiquetado de costos (Cost Allocation Tags: user:Project, user:CostCenter).
# =============================================================================

# 1. Presupuesto Global Mensual para la Plataforma FreshBox SpA
resource "aws_budgets_budget" "freshbox_global" {
  count             = var.enable_aws_budget ? 1 : 0
  name              = "${var.project_name}-global-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  cost_filter {
    name = "TagKeyValue"
    values = [
      "user:Project$${var.common_tags.Project}",
      "user:CostCenter$${var.common_tags.CostCenter}"
    ]
  }

  # Alerta 1: Consumo real alcanza el 70% del presupuesto mensual
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 70
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  # Alerta 2: Consumo real alcanza el 85% del presupuesto mensual
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 85
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  # Alerta 3: Pronostico de consumo excede el 100% del presupuesto mensual
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  tags = {
    Name      = "${var.project_name}-global-budget"
    Component = "finops-governance"
  }
}

# 2. Presupuesto Especifico para la Capa de Computo / Contenedores (ECS Fargate)
resource "aws_budgets_budget" "freshbox_containers" {
  count             = var.enable_aws_budget ? 1 : 0
  name              = "${var.project_name}-containers-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.containers_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  cost_filter {
    name = "TagKeyValue"
    values = [
      "user:Component$containers-app"
    ]
  }

  # Alerta cuando el computo de contenedores supera el 80% de su limite
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  # Alerta si el pronostico de computo sobrepasara el 100%
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  tags = {
    Name      = "${var.project_name}-containers-budget"
    Component = "finops-containers"
  }
}
