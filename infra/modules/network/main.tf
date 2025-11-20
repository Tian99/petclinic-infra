#############################################
# 1. VPC Network
#############################################

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.project_id
}


#############################################
# 2. Subnets (EU + US)
#############################################

resource "google_compute_subnetwork" "eu_subnet" {
  name          = "${var.network_name}-eu-subnet"
  region        = var.eu_region
  ip_cidr_range = "10.1.0.0/20"
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "us_subnet" {
  name          = "${var.network_name}-us-subnet"
  region        = var.us_region
  ip_cidr_range = "10.2.0.0/20"
  network       = google_compute_network.vpc.id
}


#############################################
# 3. Private Service Access (for Cloud SQL)
#############################################

resource "google_compute_global_address" "private_service_range" {
  name          = "${var.network_name}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "services/servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}
