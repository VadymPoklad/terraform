resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_-!"
}

resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-db-sg"
  description = "Allow PostgreSQL inbound traffic from VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-db-sg"
  }
}

resource "aws_db_instance" "this" {
  identifier             = "${var.environment}-postgres"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"       # Безкоштовний рівень (Free Tier)
  allocated_storage      = 20                  # Безкоштовний рівень, максимум 20GB
  db_name                = "jiraclone"
  username               = "jiradmin"
  password               = random_password.db_password.result
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true                # Щоб легко видаляти (destroy) під час розробки
  publicly_accessible    = false
  
  backup_retention_period = 0                  # Вимкнено автоматичні бэкапи через обмеження акаунту AWS
}

resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "prod/db"
  recovery_window_in_days = 0                  # Видаляти одразу, без вікна відновлення (для зручності dev)
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    DATABASE_URL = "postgresql://${aws_db_instance.this.username}:${urlencode(random_password.db_password.result)}@${aws_db_instance.this.endpoint}/${aws_db_instance.this.db_name}"
  })
}