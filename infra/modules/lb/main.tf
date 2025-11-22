resource "google_compute_global_address" "lb_ip" {
  name    = "petclinic-global-ip"
  project = var.project_id
}

resource "google_compute_managed_ssl_certificate" "ssl" {
  name    = "petclinic-ssl-cert"
  project = var.project_id

  managed {
    domains = [var.domain_name]  # petclinic.oju.app
  }
}

resource "google_compute_health_check" "http_health_check" {
  name    = "petclinic-health-check"
  project = var.project_id

  http_health_check {
    request_path = "/healthz"
    port         = 80
  }

  check_interval_sec  = 2
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 1
}

resource "google_compute_region_network_endpoint_group" "eu_neg" {
  name                  = "petclinic-eu-neg"
  project               = var.project_id
  region                = var.eu_region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.eu_service_name
  }
}

resource "google_compute_region_network_endpoint_group" "us_neg" {
  name                  = "petclinic-us-neg"
  project               = var.project_id
  region                = var.us_region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.us_service_name
  }
}

resource "google_compute_backend_service" "backend" {
  name                  = "petclinic-backend"
  project               = var.project_id
  protocol              = "HTTP"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [google_compute_health_check.http_health_check.id]

  backend {
    group = google_compute_region_network_endpoint_group.eu_neg.id
  }

  backend {
    group = google_compute_region_network_endpoint_group.us_neg.id
  }
}

resource "google_compute_url_map" "urlmap" {
  name            = "petclinic-urlmap"
  project         = var.project_id
  default_service = google_compute_backend_service.backend.id
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name    = "petclinic-https-proxy"
  project = var.project_id

  url_map          = google_compute_url_map.urlmap.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl.id]
}

resource "google_compute_global_forwarding_rule" "https_rule" {
  name    = "petclinic-https-rule"
  project = var.project_id

  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}