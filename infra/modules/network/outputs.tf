output "network_self_link" {
  value       = google_compute_network.vpc.self_link
  description = "Self link of the created VPC"
}

output "eu_subnet" {
  value       = google_compute_subnetwork.eu_subnet.self_link
  description = "EU subnet self link"
}

output "us_subnet" {
  value       = google_compute_subnetwork.us_subnet.self_link
  description = "US subnet self link"
}
