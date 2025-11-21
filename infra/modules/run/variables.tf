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

variable "db_private_ip_eu" {
  type        = string
  description = "Private IP of Cloud SQL instance (EU)"
}

variable "db_private_ip_us" {
  type        = string
  description = "Private IP of Cloud SQL instance (US) if replica exists"
}

variable "db_user" {
  type        = string
  description = "Database username"
}

variable "db_password" {
  type        = string
  description = "Database password"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "image" {
  type        = string
  description = "Container image for Cloud Run service"
}