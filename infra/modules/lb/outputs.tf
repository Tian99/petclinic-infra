output "lb_url" {
  value       = "https://${google_compute_global_address.lb_ip.address}"
  description = "Global HTTPS Load Balancer URL"
}
