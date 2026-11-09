# ==============================================================================
# Amazon API Gateway (HTTP API v2) - Fachada Unificada de Microservicios
# Evaluacion EA3 / ARY1102 - Arquitectura Cloud
# ==============================================================================

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api-gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }

  tags = {
    Name        = "${var.project_name}-api-gateway"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true

  tags = {
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# Integraciones Lambda
# ------------------------------------------------------------------------------

# Integracion: Carrito
resource "aws_apigatewayv2_integration" "cart" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.cart_function.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "cart_any" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /api/cart"
  target    = "integrations/${aws_apigatewayv2_integration.cart.id}"
}

resource "aws_apigatewayv2_route" "cart_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /api/cart/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.cart.id}"
}

resource "aws_lambda_permission" "apigw_cart" {
  statement_id  = "AllowAPIGatewayInvokeCart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cart_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# Integracion: Crear Orden
resource "aws_apigatewayv2_integration" "order_create" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.order_create.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "order_create_post" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /api/orders"
  target    = "integrations/${aws_apigatewayv2_integration.order_create.id}"
}

resource "aws_lambda_permission" "apigw_order_create" {
  statement_id  = "AllowAPIGatewayInvokeOrderCreate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_create.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# ------------------------------------------------------------------------------
# Integracion EKS (CRUD de Catalogo via ALB Ingress)
# ------------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "eks_products" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "${var.eks_alb_dns_name}/api/products"
}

resource "aws_apigatewayv2_route" "eks_products_any" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /api/products"
  target    = "integrations/${aws_apigatewayv2_integration.eks_products.id}"
}

resource "aws_apigatewayv2_route" "eks_products_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /api/products/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.eks_products.id}"
}
