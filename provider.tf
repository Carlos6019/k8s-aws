#provider aws
provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

#provider kubernetes
provider "kubernetes" {
  config_path = var.config_path
}
