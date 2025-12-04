# Service Account and IAM configuration
# Requirements: 8.1-8.5

# Requirement 8.1: Create Cloud Run service account
resource "google_service_account" "cloudrun" {
  account_id   = "cloudrun-api"
  display_name = "Cloud Run API Service Account"
}

# Requirements 8.2, 8.3, 8.4: Assign minimal privilege roles
locals {
  cloudrun_roles = [
    "roles/cloudsql.client",              # 8.2: Cloud SQL Client
    "roles/storage.objectAdmin",          # 8.3: Storage Object Admin
    "roles/secretmanager.secretAccessor", # 8.4: Secret Manager Secret Accessor
    "roles/compute.networkUser",          # Required for VPC access
  ]
}

resource "google_project_iam_member" "cloudrun_roles" {
  for_each = toset(local.cloudrun_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Requirement 8.5: Output service account email
output "service_account_email" {
  description = "Cloud Run service account email"
  value       = google_service_account.cloudrun.email
}
