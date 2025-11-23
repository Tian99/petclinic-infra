terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

# ------------------------------------------------------
# Enable Required APIs
# ------------------------------------------------------

resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"
}

resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "cloudfunctions" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
}

# ------------------------------------------------------
# Pub/Sub Topic
# ------------------------------------------------------

resource "google_pubsub_topic" "regional_failover" {
  name    = var.pubsub_topic_name
  project = var.project_id
}

resource "google_monitoring_notification_channel" "regional_failover" {
  display_name = "regional-failover-channel"
  type         = "pubsub"
  project      = var.project_id

  labels = {
    topic = google_pubsub_topic.regional_failover.id
  }
}

# ------------------------------------------------------
# Storage for Function Source
# ------------------------------------------------------

resource "google_storage_bucket" "function_src" {
  name          = "${var.project_id}-regional-failover-src"
  project       = var.project_id
  location      = var.region
  force_destroy = true
}

data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function_src"
  output_path = "${path.module}/function.zip"
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "regional-failover-fn.zip"
  bucket = google_storage_bucket.function_src.name
  source = data.archive_file.function_zip.output_path
}

# ------------------------------------------------------
# Service Account for Cloud Function
# ------------------------------------------------------

resource "google_service_account" "failover_sa" {
  account_id   = "regional-failover-fn"
  display_name = "Regional Failover Function SA"
  project      = var.project_id
}

resource "google_project_iam_member" "failover_sa_lb_admin" {
  project = var.project_id
  role    = "roles/compute.loadBalancerAdmin"
  member  = "serviceAccount:${google_service_account.failover_sa.email}"
}

# Cloud Build service account to run builds
resource "google_project_iam_member" "failover_sa_cloudbuild" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.failover_sa.email}"
}

# ------------------------------------------------------
# Cloud Function GEN1 (稳定无坑)
# ------------------------------------------------------

resource "google_cloudfunctions_function" "regional_failover" {
  name        = var.function_name
  project     = var.project_id
  region      = var.region
  runtime     = "python311"
  entry_point = "main"

  available_memory_mb = 256
  timeout             = 60

  source_archive_bucket = google_storage_bucket.function_src.name
  source_archive_object = google_storage_bucket_object.function_zip.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.regional_failover.name
  }
  service_account_email = google_service_account.failover_sa.email

  environment_variables = {
    PROJECT_ID       = var.project_id
    BACKEND_SERVICE  = var.backend_service_name
    EU_NEG_NAME      = var.eu_neg_name
    US_NEG_NAME      = var.us_neg_name
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.pubsub,
    google_project_service.cloudbuild
  ]
}

resource "google_project_iam_member" "compute_sa_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# ------------------------------------------------------
# Uptime Check
# ------------------------------------------------------

resource "google_monitoring_uptime_check_config" "healthcheck" {
  display_name = "petclinic-healthcheck"

  http_check {
    path    = "/healthz"
    port    = 443
    use_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      host = var.healthcheck_host
    }
  }

  timeout = "10s"
  period  = "60s"
}

# ------------------------------------------------------
# Alert Policy (发送到 Pub/Sub)
# ------------------------------------------------------

resource "google_monitoring_alert_policy" "regional_failure" {
  project      = var.project_id
  display_name = "Regional Failure: healthz down on ${var.healthcheck_host}"
  combiner     = "OR"

  conditions {
    display_name = "Uptime check failed for ${var.healthcheck_host}"

    condition_threshold {
      filter = <<-EOT
        metric.type="monitoring.googleapis.com/uptime_check/check_passed"
        AND resource.type="uptime_url"
        AND resource.label."host"="${var.healthcheck_host}"
      EOT

      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "60s"
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.regional_failover.name
  ]
}