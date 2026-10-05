# ==============================================================================
# Amazon RDS MySQL Multi-AZ - Base de Datos Relacional PaaS Gestionada
# Evaluacion EA2 / ARY1102 - Arquitectura Cloud
# ==============================================================================

# 1. DB Subnet Group en Subredes Privadas de Datos (Multi-AZ)
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group para RDS MySQL Multi-AZ en subredes privadas de datos"
  subnet_ids  = aws_subnet.private_data[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# 2. Instancia RDS MySQL Multi-AZ (PaaS)
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  allocated_storage      = 20
  max_allocated_storage  = 50
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  backup_retention_period = 7

  tags = {
    Name = "${var.project_name}-rds-mysql-multiaz"
  }
}
