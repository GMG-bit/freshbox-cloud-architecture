# Amazon ECR - 5 repositorios para imagenes Docker
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
  for_each = local.ecr_repos

  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-${each.key}"
    Project = var.project_name
  }
}
