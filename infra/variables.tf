variable "project_id" {
  type        = string
  description = "GCP Project ID where infrastructure will be deployed."
}

variable "default_region" {
  type        = string
  description = "Primary region used by the root provider."
  default     = "europe-west1"
}

variable "eu_region" {
  type        = string
  description = "Region for EU deployments."
  default     = "europe-west1"
}

variable "us_region" {
  type        = string
  description = "Region for US deployments."
  default     = "us-central1"
}

variable "db_tier" {
  type        = string
  description = "Cloud SQL instance tier."
  default     = "db-custom-2-4096"
}

variable "db_name" {
  type        = string
  description = "Default database name inside Cloud SQL."
  default     = "petclinic"
}

variable "db_user" {
  type        = string
  description = "Database username for Cloud SQL."
  default     = "petclinic_user"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database password."
}

variable "network_name" {
  type        = string
  default     = "petclinic-vpc"
  description = "VPC Network name"
}

variable "env" {
  type        = string
  description = "Environment name (dev / staging / prod)."
  default     = "dev"
}

variable "image" {
  type        = string
  description = "Docker image used by Cloud Run services."
}
