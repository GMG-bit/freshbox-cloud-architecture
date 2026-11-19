# ==============================================================================
# Amazon SQS - Desacoplamiento Asincrono y Resiliencia (Queue + DLQ)
# Evaluacion EA3 / ARY1102 - Arquitectura Cloud
# ==============================================================================

# 1. Dead Letter Queue (DLQ) para aislamiento de fallos tras 3 reintentos
resource "aws_sqs_queue" "orders_dlq" {
  name                      = "${var.sqs_queue_name}-dlq"
  message_retention_seconds = 1209600 # 14 dias para analisis forense de mensajes fallidos
  sqs_managed_sse_enabled   = true

  tags = {
    Name        = "${var.sqs_queue_name}-dlq"
    Environment = var.environment
  }
}

# 2. Cola Principal de Procesamiento de Ordenes con Redrive Policy
resource "aws_sqs_queue" "orders_queue" {
  name                      = var.sqs_queue_name
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB
  message_retention_seconds = 345600 # 4 dias
  receive_wait_time_seconds = 20     # Long Polling para reducir llamadas API y costos
  visibility_timeout_seconds = 60    # Suficiente para ejecucion de Lambda order-process
  sqs_managed_sse_enabled   = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orders_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = var.sqs_queue_name
    Environment = var.environment
  }
}
