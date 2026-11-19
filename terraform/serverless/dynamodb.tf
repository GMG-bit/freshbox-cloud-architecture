# ==============================================================================
# Amazon DynamoDB - Tabla de Carrito Temporal con TTL
# Evaluacion EA3 / ARY1102 - Arquitectura Cloud
# ==============================================================================

resource "aws_dynamodb_table" "cart" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST" # On-Demand para escalamiento a cero y ahorro maximo
  hash_key     = "userId"
  range_key    = "productId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "productId"
    type = "S"
  }

  # TTL de 24 horas para autolimpieza de carritos sin impacto operativo
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-cart-table"
    Environment = var.environment
  }
}
