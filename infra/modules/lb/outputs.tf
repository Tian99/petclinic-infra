output "lb_ip" {
  description = "Global IP address of the HTTPS Load Balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "lb_url" {
  description = "HTTPS URL with custom domain"
  value       = "https://${var.domain_name}"
}