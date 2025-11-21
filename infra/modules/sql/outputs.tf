output "primary_connection_name" {
  value       = google_sql_database_instance.primary.connection_name
  description = "Connection name for primary Cloud SQL instance (for EU Cloud Run)."
}

output "replica_connection_name" {
  value       = google_sql_database_instance.replica.connection_name
  description = "Connection name for replica Cloud SQL instance (for US Cloud Run)."
}

output "primary_instance_name" {
  value       = google_sql_database_instance.primary.name
  description = "Primary Cloud SQL instance ID."
}

output "primary_private_ip" {
  value = google_sql_database_instance.primary.private_ip_address
}

output "replica_private_ip" {
  value = google_sql_database_instance.replica.private_ip_address
}