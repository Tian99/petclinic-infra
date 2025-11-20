variable "project_id" {
  type = string
}

variable "primary_region" {
  type        = string
  description = "Region for primary Cloud SQL instance (EU)."
}

variable "replica_region" {
  type        = string
  description = "Region for read replica Cloud SQL instance (US)."
}

variable "db_name" {
  type        = string
  description = "Database name to create inside the primary instance."
}

variable "db_user" {
  type        = string
  description = "Database user name."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database user password."
}

variable "db_tier" {
  type        = string
  description = "Cloud SQL instance machine tier."
  default     = "db-custom-2-4096"
}

variable "vpc_self_link" {
  type        = string
  description = "Self link of the VPC network used for private IP."
}

# 先预留，后面如果想玩得更细（每个 region 单独 subnet / PSC）可以用上
variable "eu_subnet" {
  type        = string
  description = "EU subnet self link or name (reserved for advanced setups)."
  default     = ""
}

variable "us_subnet" {
  type        = string
  description = "US subnet self link or name (reserved for advanced setups)."
  default     = ""
}
