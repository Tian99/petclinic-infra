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


resource "google_cloudfunctions_function" "regional_failover" {
  name        = var.function_name
  description = "Automatically shift traffic to EU when US region fails"
  project     = var.project_id
  region      = var.region
  runtime     = "python311"
  entry_point = "main"

  available_memory_mb   = 256
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
}

resource "google_monitoring_uptime_check_config" "healthcheck" {
  display_name = "petclinic-healthcheck"

  http_check {
    path = "/healthz"
    port = 443
    use_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      host = var.healthcheck_host
    }
  }

  timeout = "10s"
  period  = "30s"
}

resource "google_monitoring_alert_policy" "regional_failure" {
  display_name = "Regional Failure: healthz down on ${var.healthcheck_host}"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Uptime check failed on ${var.healthcheck_host}"

    condition_threshold {
      filter = <<-EOT
        metric.type="monitoring.googleapis.com/uptime_check/check_passed"
        AND resource.type="uptime_url"
        AND resource.label."host"="${var.healthcheck_host}"
      EOT

      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "15s"

      aggregations {
        alignment_period   = "15s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.regional_failover.name
  ]

  documentation {
    content   = "Automatically trigger regional failover when uptime check fails."
    mime_type = "text/markdown"
  }

  user_labels = {
    scenario = "regional-failover"
  }
}