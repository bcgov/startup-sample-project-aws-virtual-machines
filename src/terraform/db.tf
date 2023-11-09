# db.tf

resource "aws_db_subnet_group" "data_subnet" {
  name                   = "data-subnet"
  subnet_ids             = module.network.aws_subnet_ids.data.ids

  tags = var.common_tags
}

resource "aws_rds_cluster" "mysql" {
  cluster_identifier      = "bcparks-dam-mysql-cluster"
  engine                  = "aurora-mysql"
  engine_mode             = "serverless"
  database_name           = "resourcespace"
  scaling_configuration {
    auto_pause               = true
    max_capacity             = 16
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
  master_username         = local.secrets.mysql_username
  master_password         = local.secrets.mysql_password
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  db_subnet_group_name    = aws_db_subnet_group.data_subnet.name
  storage_encrypted       = true
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  skip_final_snapshot     = true
  enable_http_endpoint    = true
  final_snapshot_identifier = "resourcespace-finalsnapshot"

  tags = var.common_tags
}