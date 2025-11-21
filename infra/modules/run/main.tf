#############################################
# 1. EU Region VPC Connector
#############################################

resource "google_vpc_access_connector" "eu_connector" {
  name          = "pc-eu-conn"
  region        = var.eu_region
  network       = var.vpc_self_link
  ip_cidr_range = "10.8.0.0/28"
}

#############################################
# 2. US Region VPC Connector
#############################################

resource "google_vpc_access_connector" "us_connector" {
  name          = "pc-us-conn"
  region        = var.us_region
  network       = var.vpc_self_link
  ip_cidr_range = "10.9.0.0/28"
}

#############################################
# 3. EU Region Cloud Run (v2)
#############################################

resource "google_cloud_run_v2_service" "eu_service" {
  name     = "petclinic-eu"
  location = var.eu_region

  template {
    containers {
      image = var.image

      # ---------- DB Credentials ----------
      env { name = "DB_USER"     value = var.db_user }
      env { name = "DB_PASSWORD" value = var.db_password }
      env { name = "DB_NAME"     value = var.db_name }

      # ---------- DB Host (Private IP) ----------
      env {
        name  = "DB_HOST"
        value = var.db_private_ip_eu
      }

      # ---------- JDBC URL ----------
      env {
        name  = "DB_URL"
        value = "jdbc:postgresql://${var.db_private_ip_eu}:5432/${var.db_name}"
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    vpc_access {
      connector = google_vpc_access_connector.eu_connector.id
      egress    = "ALL_TRAFFIC"
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

#############################################
# 4. US Region Cloud Run (v2)
#############################################

resource "google_cloud_run_v2_service" "us_service" {
  name     = "petclinic-us"
  location = var.us_region

  template {
    containers {
      image = var.image

      # ---------- DB Credentials ----------
      env { name = "DB_USER"     value = var.db_user }
      env { name = "DB_PASSWORD" value = var.db_password }
      env { name = "DB_NAME"     value = var.db_name }

      # ---------- DB Host (Private IP of Replica) ----------
      env {
        name  = "DB_HOST"
        value = var.db_private_ip_us
      }

      # ---------- JDBC URL ----------
      env {
        name  = "DB_URL"
        value = "jdbc:postgresql://${var.db_private_ip_us}:5432/${var.db_name}"
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    vpc_access {
      connector = google_vpc_access_connector.us_connector.id
      egress    = "ALL_TRAFFIC"
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}