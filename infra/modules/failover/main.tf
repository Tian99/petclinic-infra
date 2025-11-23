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
}

resource "google_monitoring_notification_channel" "regional_failover" {
  display_name = "regional-failover-channel"
  type         = "pubsub"
  project      = var.project_id

  labels = {
    topic = google_pubsub_topic.regional_failover.id
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