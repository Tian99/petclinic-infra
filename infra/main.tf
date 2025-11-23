# Network Layer

module "network" {
  source       = "./modules/network"
  project_id   = var.project_id
  network_name = var.network_name

  eu_region = var.eu_region
  us_region = var.us_region
}

# Cloud SQL Layer (Primary EU + Replica US)

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

# Cloud Run Layer (EU + US)

module "run" {
  source = "./modules/run"

  project_id = var.project_id

  eu_region = var.eu_region
  us_region = var.us_region

  vpc_self_link = module.network.network_self_link

  db_connection_name_eu = module.sql.primary_connection_name
  db_connection_name_us = module.sql.replica_connection_name

  db_private_ip_eu = module.sql.primary_private_ip
  db_private_ip_us = module.sql.replica_private_ip

  db_user     = var.db_user
  db_password = var.db_password
  db_name     = var.db_name

  image = var.image
}

# Global HTTPS Load Balancer

module "lb" {
  source     = "./modules/lb"
  project_id = var.project_id

  domain_name      = "petclinic.oju.app"

  eu_region        = var.eu_region
  us_region        = var.us_region

  eu_service_name  = "petclinic-eu"
  us_service_name  = "petclinic-us"
}

module "failover" {
  source = "./modules/failover"

  project_id           = var.project_id
  project_number = var.project_number
  region               = var.eu_region

  backend_service_name = "petclinic-backend"
  eu_neg_name          = "petclinic-eu-neg"
  us_neg_name          = "petclinic-us-neg"
  healthcheck_host     = "petclinic.oju.app"
  us_run_url           = module.run.us_url
}

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
