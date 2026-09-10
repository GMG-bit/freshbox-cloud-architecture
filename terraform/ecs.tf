resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 1
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-frontend:${var.ecr_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    },
    {
      name      = "get-products"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-get-products:${var.ecr_image_tag}"
      essential = false
      portMappings = [
        {
          containerPort = 3001
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_instance.mysql.private_ip },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_PASS", value = var.db_password },
        { name = "DB_NAME", value = var.db_name },
        { name = "PORT", value = "3001" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "get-products"
        }
      }
    },
    {
      name      = "create-product"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-create-product:${var.ecr_image_tag}"
      essential = false
      portMappings = [
        {
          containerPort = 3002
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_instance.mysql.private_ip },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_PASS", value = var.db_password },
        { name = "DB_NAME", value = var.db_name },
        { name = "PORT", value = "3002" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "create-product"
        }
      }
    },
    {
      name      = "update-product"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-update-product:${var.ecr_image_tag}"
      essential = false
      portMappings = [
        {
          containerPort = 3003
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_instance.mysql.private_ip },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_PASS", value = var.db_password },
        { name = "DB_NAME", value = var.db_name },
        { name = "PORT", value = "3003" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "update-product"
        }
      }
    },
    {
      name      = "delete-product"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-delete-product:${var.ecr_image_tag}"
      essential = false
      portMappings = [
        {
          containerPort = 3004
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_instance.mysql.private_ip },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_PASS", value = var.db_password },
        { name = "DB_NAME", value = var.db_name },
        { name = "PORT", value = "3004" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "delete-product"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name                              = "${var.project_name}-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = var.ecs_desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = aws_subnet.private_app[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}
