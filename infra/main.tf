# Terraform configuration and provider setup
# Requirements: 12.1, 12.5, 1.1-1.9

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
  backend "gcs" {
    bucket = "minna-senshuken-tf-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# APIs to enable
# Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8
locals {
  apis = [
    "run.googleapis.com",              # 1.1 Cloud Run API
    "sqladmin.googleapis.com",         # 1.2 Cloud SQL Admin API
    "storage-api.googleapis.com",      # 1.3 Cloud Storage API
    "secretmanager.googleapis.com",    # 1.4 Secret Manager API
    "artifactregistry.googleapis.com", # 1.5 Artifact Registry API
    "cloudbuild.googleapis.com",       # 1.6 Cloud Build API
    "compute.googleapis.com",          # 1.7 Compute Engine API
    "servicenetworking.googleapis.com", # 1.8 Service Networking API
  ]
}

# Requirement 1.9: Error messages include failed API name (handled by Terraform automatically)
resource "google_project_service" "apis" {
  for_each           = toset(local.apis)
  service            = each.value
  disable_on_destroy = false
}
