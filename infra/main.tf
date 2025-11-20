#############################################
# Network Layer
#############################################

module "network" {
  source       = "./modules/network"
  project_id   = var.project_id
  network_name = var.network_name

  eu_region = var.eu_region
  us_region = var.us_region
}


#############################################
# Cloud SQL Layer (Primary EU + Replica US)
#############################################

module "sql" {
  source = "./modules/sql"

  project_id = var.project_id

  primary_region = var.eu_region
  replica_region = var.us_region

  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password

  vpc_self_link = module.network.network_self_link
  eu_subnet     = module.network.eu_subnet
  us_subnet     = module.network.us_subnet
}


#############################################
# Cloud Run Layer (EU + US)
#############################################

module "run" {
  source = "./modules/run"

  project_id = var.project_id

  eu_region = var.eu_region
  us_region = var.us_region

  vpc_self_link = module.network.network_self_link

  db_connection_name_eu = module.sql.primary_connection_name
  db_connection_name_us = module.sql.replica_connection_name
}


#############################################
# Global HTTPS Load Balancer
#############################################

module "lb" {
  source     = "./modules/lb"
  project_id = var.project_id

  eu_region_run_url = module.run.eu_url
  us_region_run_url = module.run.us_url
}


#############################################
# Outputs
#############################################

output "lb_url" {
  value       = module.lb.lb_url
  description = "Global external load balancer URL for Petclinic"
}

output "eu_cloud_run_url" {
  value = module.run.eu_url
}

output "us_cloud_run_url" {
  value = module.run.us_url
}
