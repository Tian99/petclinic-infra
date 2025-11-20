variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "domain_name" {
  type        = string
  description = "Full domain name for HTTPS (e.g. petclinic.oju.app)"
}

variable "eu_region" {
  type        = string
  description = "Primary region for Cloud Run (e.g. europe-west1)"
}

variable "us_region" {
  type        = string
  description = "Secondary region for Cloud Run (e.g. us-central1)"
}

variable "eu_service_name" {
  type        = string
  description = "Cloud Run service name in EU region (e.g. petclinic-eu)"
}

variable "us_service_name" {
  type        = string
  description = "Cloud Run service name in US region (e.g. petclinic-us)"
}