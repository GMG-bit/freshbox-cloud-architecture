# ==============================================================================
# Outputs de Infraestructura Serverless
# ==============================================================================

output "api_gateway_endpoint" {
  description = "URL base del API Gateway HTTP"
  value       = aws_apigatewayv2_stage.prod.invoke_url
}

output "s3_website_endpoint" {
  description = "URL del sitio estatico en Amazon S3"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB de carrito"
  value       = aws_dynamodb_table.cart.name
}

output "sqs_orders_queue_url" {
  description = "URL de la cola SQS de ordenes"
  value       = aws_sqs_queue.orders_queue.id
}

output "sqs_orders_dlq_url" {
  description = "URL de la Dead Letter Queue SQS"
  value       = aws_sqs_queue.orders_dlq.id
}
