output "db_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "db_password" {
  value     = random_password.aurora_password.result
  sensitive = true
}

output "rds_security_group_id" {
  value = var.rds_security_group_id
}

output "rds_instance_count" {
  value = var.rds_instance_count
}
