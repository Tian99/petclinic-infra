

resource "google_vpc_access_connector" "eu_connector" {
  name          = "pc-eu-conn"
  region        = var.eu_region
  network       = var.vpc_self_link
  ip_cidr_range = "10.8.0.0/28"
}



resource "google_vpc_access_connector" "us_connector" {
  name          = "pc-us-conn"
  region        = var.us_region
  network       = var.vpc_self_link
  ip_cidr_range = "10.9.0.0/28"
}



resource "google_cloud_run_v2_service" "eu_service" {
  name     = "petclinic-eu"
  location = var.eu_region

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    vpc_access {
      connector = google_vpc_access_connector.eu_connector.id
      egress    = "ALL_TRAFFIC"
    }

    containers {
      image = var.image

      resources {
        cpu_idle = false
        limits = {
          cpu    = "2"
          memory = "2Gi"
        }
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "eu"
      }

      env {
        name  = "DB_USER"
        value = var.db_user
      }

      env {
        name  = "DB_PASSWORD"
        value = var.db_password
      }

      env {
        name  = "DB_NAME"
        value = var.db_name
      }

      env {
        name  = "DB_HOST"
        value = var.db_private_ip_eu
      }

      env {
        name  = "DB_URL"
        value = "jdbc:postgresql://${var.db_private_ip_eu}:5432/${var.db_name}"
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}



resource "google_cloud_run_v2_service" "us_service" {
  name     = "petclinic-us"
  location = var.us_region

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    vpc_access {
      connector = google_vpc_access_connector.us_connector.id
      egress    = "ALL_TRAFFIC"
    }

    containers {
      image = var.image

      resources {
        cpu_idle = false
        limits = {
          cpu    = "2"
          memory = "2Gi"
        }
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "us"
      }

      env {
        name  = "DB_USER"
        value = var.db_user
      }

      env {
        name  = "DB_PASSWORD"
        value = var.db_password
      }

      env {
        name  = "DB_NAME"
        value = var.db_name
      }

      env {
        name  = "DB_HOST"
        value = var.db_private_ip_us
      }

      env {
        name  = "DB_URL"
        value = "jdbc:postgresql://${var.db_private_ip_us}:5432/${var.db_name}"
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}