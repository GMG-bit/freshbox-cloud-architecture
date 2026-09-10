# AWS Backup - Plan de respaldo para EC2 MySQL
resource "aws_backup_vault" "main" {
  name = "${var.project_name}-backup-vault"

  tags = {
    Name    = "${var.project_name}-backup-vault"
    Project = var.project_name
  }
}

resource "aws_backup_plan" "mysql" {
  name = "${var.project_name}-mysql-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 * * ? *)" # Diario a las 3 AM UTC

    lifecycle {
      delete_after = 7 # Retención 7 días
    }
  }

  tags = {
    Name    = "${var.project_name}-mysql-backup"
    Project = var.project_name
  }
}

resource "aws_backup_selection" "mysql" {
  name         = "${var.project_name}-mysql-selection"
  plan_id      = aws_backup_plan.mysql.id
  iam_role_arn = data.aws_iam_role.lab_role.arn

  resources = [
    aws_instance.mysql.arn
  ]
}
