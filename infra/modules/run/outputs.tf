output "eu_url" {
  value = google_cloud_run_v2_service.eu_service.uri
}

output "us_url" {
  value = google_cloud_run_v2_service.us_service.uri
}
