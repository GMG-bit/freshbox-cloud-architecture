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

data "aws_ecr_repository" "repos" {
  for_each = local.ecr_repos
  name     = "${var.project_name}-${each.key}"
}
