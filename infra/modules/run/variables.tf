variable "project_id" {
  type = string
}

variable "eu_region" {
  type = string
}

variable "us_region" {
  type = string
}

variable "vpc_self_link" {
  type = string
}

variable "db_connection_name_eu" {
  type        = string
  description = "Cloud SQL connection string for EU region Cloud Run"
}

variable "db_connection_name_us" {
  type        = string
  description = "Cloud SQL connection string for US region Cloud Run"
}

variable "image" {
  type        = string
  description = "Container image for Cloud Run service"
  default     = "europe-west1-docker.pkg.dev/YOUR_PROJECT/petclinic/petclinic:latest"
}
