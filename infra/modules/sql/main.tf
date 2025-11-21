

resource "google_sql_database_instance" "primary" {
  name             = "petclinic-sql-eu"
  project          = var.project_id
  region           = var.primary_region
  database_version = "POSTGRES_15"

  settings {
    tier = var.db_tier
    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_self_link
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    database_flags {
      name  = "max_connections"
      value = "6000"
    }
  }

  deletion_protection = false
}


resource "google_sql_database" "primary_db" {
  name     = var.db_name
  instance = google_sql_database_instance.primary.name
}


resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.primary.name
  password = var.db_password
}


resource "google_sql_database_instance" "replica" {
  name    = "petclinic-sql-us-replica"
  project = var.project_id
  region  = var.replica_region

  database_version     = google_sql_database_instance.primary.database_version
  master_instance_name = google_sql_database_instance.primary.name

  settings {
    tier = var.db_tier

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_self_link
    }

    database_flags {
      name  = "max_connections"
      value = "6000"
    }
  }

  depends_on = [
      google_sql_database_instance.primary,
      google_sql_user.db_user,
      google_sql_database.primary_db,
  ]
}