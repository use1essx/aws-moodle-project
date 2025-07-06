resource "random_password" "aurora_password" {
  length  = 16
  special = false
}

resource "aws_db_subnet_group" "default" {
  name       = "moodle-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "moodle-db-subnet-group"
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "moodle-aurora-cluster"
  engine                 = "aurora-mysql"
  engine_mode            = "provisioned"
  master_username        = "root"
  master_password        = random_password.aurora_password.result
  database_name          = "moodledb"
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [var.rds_security_group_id]
  skip_final_snapshot    = true
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count              = var.rds_instance_count
  identifier         = "moodle-aurora-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.aurora.engine
  publicly_accessible = false
}
