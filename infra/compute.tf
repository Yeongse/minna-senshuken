# Cloud Run service configuration
# Requirements: 6.1-6.10, 11.2

# Requirements 6.1-6.8, 6.10, 11.2: Create Cloud Run service
resource "google_cloud_run_v2_service" "api" {
  name     = "minna-senshuken-api"
  location = var.region # 6.1: asia-northeast1

  template {
    service_account = google_service_account.cloudrun.email

    # Requirements 6.2, 6.3, 11.2: Scaling configuration
    scaling {
      min_instance_count = 0 # 6.2, 11.2: Cold start allowed for cost optimization
      max_instance_count = 2 # 6.3: Max 2 instances
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/minna-senshuken/api:latest"

      # Requirements 6.4, 6.5: Resource limits
      resources {
        limits = {
          cpu    = "1"      # 6.5: 1 CPU
          memory = "512Mi"  # 6.4: 512Mi memory
        }
      }

      # Requirement 6.8: Environment variables from Secret Manager
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_url.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "FIREBASE_PROJECT_ID"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.firebase_project_id.secret_id
            version = "latest"
          }
        }
      }
    }

    # Requirements 6.6, 6.7: Direct VPC Egress configuration
    vpc_access {
      network_interfaces {
        network    = google_compute_network.vpc.name
        subnetwork = google_compute_subnetwork.subnet.name
      }
      egress = "PRIVATE_RANGES_ONLY" # 6.7: Egress to private ranges only
    }
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_version.database_url,
    google_secret_manager_secret_version.firebase_project_id,
  ]
}

# Requirement 6.9: Allow unauthenticated access (public API)
resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.api.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Requirement 6.10: Output service URL
output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.api.uri
}
