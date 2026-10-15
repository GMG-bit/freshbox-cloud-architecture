# ==============================================================================
# Amazon ECR - 5 Repositorios para Microservicios Contenerizados
# Evaluacion EA2 / ARY1102 - Arquitectura Cloud
# ==============================================================================

locals {
  ecr_repos = toset([
    "frontend",
    "get-products",
    "create-product",
    "update-product",
    "delete-product"
  ])
}

resource "aws_ecr_repository" "repos" {
  for_each             = local.ecr_repos
  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${each.key}"
    Service     = each.key
    Environment = "production"
  }
}

# Import blocks nativos de Terraform (v1.5+) para repositorios pre-creados en el pipeline CI/CD
import {
  to = aws_ecr_repository.repos["frontend"]
  id = "freshbox-frontend"
}

import {
  to = aws_ecr_repository.repos["get-products"]
  id = "freshbox-get-products"
}

import {
  to = aws_ecr_repository.repos["create-product"]
  id = "freshbox-create-product"
}

import {
  to = aws_ecr_repository.repos["update-product"]
  id = "freshbox-update-product"
}

import {
  to = aws_ecr_repository.repos["delete-product"]
  id = "freshbox-delete-product"
}
