variable "project_id" {
  type        = string
  description = "GCP project id"
}

variable "region" {
  type        = string
  description = "Region for Cloud Function & bucket (e.g. europe-west1)"
}

variable "backend_service_name" {
  type        = string
  description = "Name of the global backend service (e.g. petclinic-backend)"
}

variable "eu_neg_name" {
  type        = string
  description = "Name of the EU serverless NEG (e.g. petclinic-eu-neg)"
}

variable "us_neg_name" {
  type        = string
  description = "Name of the US serverless NEG (e.g. petclinic-us-neg)"
}

variable "healthcheck_host" {
  type        = string
  description = "Hostname used by uptime check, e.g. petclinic.oju.app"
}

variable "pubsub_topic_name" {
  type        = string
  default     = "regional-failover-topic"
}

variable "function_name" {
  type        = string
  default     = "regional-failover-fn"
}