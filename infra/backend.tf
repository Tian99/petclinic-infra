terraform {
  backend "gcs" {
    bucket = "petclinic-tf-state"
    prefix = "infra"
  }
}
