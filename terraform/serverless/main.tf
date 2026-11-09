# ==============================================================================
# FreshBox SpA - Modulo Serverless (EA3 / EP3)
# Infraestructura como Codigo (Terraform)
# Servicios: API Gateway, AWS Lambda, DynamoDB, SQS, S3 Static, VPC Endpoints
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# Rol de ejecucion para AWS Academy Learner Lab
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
