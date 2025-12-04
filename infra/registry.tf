# Artifact Registry repository configuration
# Requirements: 5.1-5.3

# Requirements 5.1, 5.2: Create Docker format repository in asia-northeast1
resource "google_artifact_registry_repository" "docker" {
  repository_id = "minna-senshuken"
  location      = var.region
  format        = "DOCKER"

  depends_on = [google_project_service.apis]
}

# Requirement 5.3: Output repository full path
output "artifact_registry_path" {
  description = "Artifact Registry repository full path"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}
