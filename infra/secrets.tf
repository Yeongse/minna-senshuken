# Secret Manager configuration
# Requirements: 7.1-7.5

# Requirement 7.1: Create DATABASE_URL secret
resource "google_secret_manager_secret" "database_url" {
  secret_id = "database-url"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

# Set DATABASE_URL value from Cloud SQL connection info
resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = "mysql://${google_sql_user.app.name}:${random_password.db_password.result}@${google_sql_database_instance.main.private_ip_address}:3306/${google_sql_database.app.name}"
}

# Requirement 7.2: Create FIREBASE_PROJECT_ID secret
resource "google_secret_manager_secret" "firebase_project_id" {
  secret_id = "firebase-project-id"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

# Requirement 7.5: Set placeholder value (Firebase uses same GCP project)
resource "google_secret_manager_secret_version" "firebase_project_id" {
  secret      = google_secret_manager_secret.firebase_project_id.id
  secret_data = var.project_id
}

# Requirement 7.3: Grant secret access to Cloud Run service account
resource "google_secret_manager_secret_iam_member" "database_url_access" {
  secret_id = google_secret_manager_secret.database_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "firebase_project_id_access" {
  secret_id = google_secret_manager_secret.firebase_project_id.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Requirement 7.4: Output created secret names
output "secret_names" {
  description = "List of created secret names"
  value = [
    google_secret_manager_secret.database_url.secret_id,
    google_secret_manager_secret.firebase_project_id.secret_id,
  ]
}
