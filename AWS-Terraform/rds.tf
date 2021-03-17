# PostgreSQL db for app

data "aws_secretsmanager_secret" "pg_taskdb_secret" {
  name = "pg_taskdb_secret"
}

data "aws_secretsmanager_secret_version" "pg_taskdb_version" {
  secret_id = data.aws_secretsmanager_secret.pg_taskdb_secret.id
}

locals {
  taskdb_password = data.aws_secretsmanager_secret_version.pg_taskdb_version.secret_string
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id, aws_subnet.private_subnet[2].id]

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_instance" "pg-taskdb" {
  allocated_storage    = 5
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  engine               = "postgres"
  engine_version       = "10"
  identifier           = "pg-taskdb"
  instance_class       = "db.t3.micro"
  password             = local.taskdb_password
  skip_final_snapshot  = true
  storage_encrypted    = true
  username             = "postgres"
}
