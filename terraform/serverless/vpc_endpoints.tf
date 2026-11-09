# ==============================================================================
# Amazon VPC Endpoints (Gateway) - Conectividad Privada para DynamoDB y S3
# Evaluacion EA3 / ARY1102 - Arquitectura Cloud
# ==============================================================================

# Data source de tablas de ruteo de la VPC si se especifica vpc_id
data "aws_route_tables" "private" {
  count  = var.vpc_id != "" ? 1 : 0
  vpc_id = var.vpc_id
}

# 1. Gateway Endpoint para Amazon DynamoDB (Trafico interno sin costo de NAT)
resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.vpc_id != "" ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.private[0].ids

  tags = {
    Name        = "${var.project_name}-vpce-dynamodb"
    Environment = var.environment
  }
}

# 2. Gateway Endpoint para Amazon S3
resource "aws_vpc_endpoint" "s3" {
  count             = var.vpc_id != "" ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.private[0].ids

  tags = {
    Name        = "${var.project_name}-vpce-s3"
    Environment = var.environment
  }
}
