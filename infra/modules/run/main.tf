#############################################
# 1. EU Region VPC Connector
#############################################

resource "google_vpc_access_connector" "eu_connector" {
  name = "petclinic-eu-vpc-connector"
  region = var.eu_region
  network = var.vpc_self_link
  ip_cidr_range = "10.8.0.0/28"
}


#############################################
# 2. US Region VPC Connector
#############################################

resource "google_vpc_access_connector" "us_connector" {
  name = "petclinic-us-vpc-connector"
  region = var.us_region
  network = var.vpc_self_link
  ip_cidr_range = "10.9.0.0/28"
}


#############################################
# 3. EU Region Cloud Run (v2 API)
#############################################

resource "google_cloud_run_v2_service" "eu_service" {
  name     = "petclinic-eu"
  location = var.eu_region

  template {
    containers {
      image = var.image

      env {
        name  = "DB_CONNECTION"
        value = var.db_connection_name_eu
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
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}


#############################################
# 4. US Region Cloud Run (v2 API)
#############################################

resource "google_cloud_run_v2_service" "us_service" {
  name     = "petclinic-us"
  location = var.us_region

  template {
    containers {
      image = var.image

      env {
        name  = "DB_CONNECTION"
        value = var.db_connection_name_us
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
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}
