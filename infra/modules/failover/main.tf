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

resource "google_project_service" "eventarc" {
  project = var.project_id
  service = "eventarc.googleapis.com"
}

resource "google_project_service" "cloudfunctions" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
}

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

resource "google_pubsub_topic" "regional_failover" {
  name    = var.pubsub_topic_name
  project = var.project_id

  depends_on = [google_project_service.pubsub]
}

resource "google_monitoring_notification_channel" "regional_failover" {
  display_name = "regional-failover-channel"
  type         = "pubsub"
  project      = var.project_id

  labels = {
    topic = google_pubsub_topic.regional_failover.id
  }
}

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

resource "google_project_iam_member" "cf_build_storage" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_build_artifact" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_serviceagent_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-cloudfunctions.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_serviceagent_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-cloudfunctions.iam.gserviceaccount.com"
}

resource "google_cloudfunctions2_function" "regional_failover" {
  name     = var.function_name
  project  = var.project_id
  location = var.region

  depends_on = [
    google_project_service.eventarc,
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild,
    google_project_service.monitoring,
    google_project_service.pubsub
  ]

  build_config {
    runtime     = "python311"
    entry_point = "main"
    source {
      storage_source {
        bucket = google_storage_bucket.function_src.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.failover_sa.email
    environment_variables = {
      PROJECT_ID       = var.project_id
      BACKEND_SERVICE  = var.backend_service_name
      EU_NEG_NAME      = var.eu_neg_name
      US_NEG_NAME      = var.us_neg_name
    }
  }

  event_trigger {
    event_type   = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.regional_failover.id
  }
}

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

resource "google_monitoring_alert_policy" "regional_failure" {
  display_name = "Regional Failure: healthz down on ${var.healthcheck_host}"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Uptime check failed"

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