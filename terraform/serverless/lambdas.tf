# ==============================================================================
# AWS Lambda - Logica Serverless (Cart, Order Create, Order Process)
# Evaluacion EA3 / ARY1102 - Arquitectura Cloud (FreshBox SpA)
# Runtime: Node.js 20.x con AWS SDK v3
# ==============================================================================

# 1. Empaquetado de Codigo Node.js
data "archive_file" "cart_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../app/lambdas-nodejs/procesar-carrito"
  output_path = "${path.module}/cart_function.zip"
}

data "archive_file" "order_create_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../app/lambdas-nodejs/crear-orden"
  output_path = "${path.module}/order_create.zip"
}

data "archive_file" "order_process_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../app/lambdas-nodejs/procesar-orden"
  output_path = "${path.module}/order_process.zip"
}

# 2. Lambda: Cart Function (DynamoDB)
resource "aws_lambda_function" "cart_function" {
  filename         = data.archive_file.cart_zip.output_path
  function_name    = "${var.project_name}-procesar-carrito"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 10
  memory_size      = 256
  source_code_hash = data.archive_file.cart_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.cart.name
    }
  }

  tags = {
    Name        = "${var.project_name}-procesar-carrito"
    Environment = var.environment
  }
}

# 3. Lambda: Order Create (DynamoDB + SQS)
resource "aws_lambda_function" "order_create" {
  filename         = data.archive_file.order_create_zip.output_path
  function_name    = "${var.project_name}-crear-orden"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 10
  memory_size      = 256
  source_code_hash = data.archive_file.order_create_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.cart.name
      QUEUE_URL  = aws_sqs_queue.orders_queue.id
    }
  }

  tags = {
    Name        = "${var.project_name}-crear-orden"
    Environment = var.environment
  }
}

# 4. Lambda: Order Process (SQS Event -> MySQL RDS + DynamoDB)
resource "aws_lambda_function" "order_process" {
  filename         = data.archive_file.order_process_zip.output_path
  function_name    = "${var.project_name}-procesar-orden"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 512
  source_code_hash = data.archive_file.order_process_zip.output_base64sha256

  # Configuracion opcional de VPC si se proporcionan subredes privadas para acceso a RDS
  dynamic "vpc_config" {
    for_each = length(var.private_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = var.lambda_security_group_ids
    }
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.cart.name
      DB_HOST    = var.db_host
      DB_USER    = var.db_user
      DB_PASS    = var.db_password
      DB_NAME    = var.db_name
      DB_PORT    = var.db_port
    }
  }

  tags = {
    Name        = "${var.project_name}-procesar-orden"
    Environment = var.environment
  }
}

# 5. Gatillador de Eventos SQS -> Lambda Order Process
resource "aws_lambda_event_source_mapping" "sqs_order_trigger" {
  event_source_arn = aws_sqs_queue.orders_queue.arn
  function_name    = aws_lambda_function.order_process.arn
  batch_size       = 10
  enabled          = true
}
