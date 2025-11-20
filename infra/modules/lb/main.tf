#############################################
# 1. Global IP Address
#############################################

resource "google_compute_global_address" "lb_ip" {
  name = "petclinic-global-ip"
}


#############################################
# 2. Managed HTTPS Certificate
#############################################

resource "google_compute_managed_ssl_certificate" "ssl" {
  name = "petclinic-ssl-cert"

  managed {
    domains = ["petclinic.example.com"] # TODO: replace with your domain
  }
}


#############################################
# 3. Serverless NEGs for Cloud Run
#############################################

resource "google_compute_region_network_endpoint_group" "eu_neg" {
  name                  = "petclinic-eu-neg"
  network_endpoint_type = "SERVERLESS"
  region                = "europe-west1"

  cloud_run {
    service = split("/", var.eu_region_run_url)[-1]
  }
}

resource "google_compute_region_network_endpoint_group" "us_neg" {
  name                  = "petclinic-us-neg"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"

  cloud_run {
    service = split("/", var.us_region_run_url)[-1]
  }
}


#############################################
# 4. Backend services
#############################################

resource "google_compute_backend_service" "backend" {
  name     = "petclinic-backend"
  protocol = "HTTP"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.eu_neg.id
  }

  backend {
    group = google_compute_region_network_endpoint_group.us_neg.id
  }
}


#############################################
# 5. URL map
#############################################

resource "google_compute_url_map" "urlmap" {
  name            = "petclinic-urlmap"
  default_service = google_compute_backend_service.backend.id
}


#############################################
# 6. HTTPS Proxy
#############################################

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "petclinic-https-proxy"
  url_map          = google_compute_url_map.urlmap.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl.id]
}


#############################################
# 7. Global Forwarding Rule
#############################################

resource "google_compute_global_forwarding_rule" "https_rule" {
  name                  = "petclinic-https-rule"
  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL"
}
