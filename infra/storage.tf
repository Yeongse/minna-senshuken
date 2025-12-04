# Cloud Storage bucket configuration
# Requirements: 4.1-4.6, 11.3

# Requirements 4.1, 4.2, 4.3: Create image storage bucket in asia-northeast1 with Standard class
resource "google_storage_bucket" "images" {
  name          = "${var.project_id}-images"
  location      = var.region
  storage_class = "STANDARD"

  # Requirement 4.4: Disable public access (uniform bucket-level access)
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Requirement 4.5: Lifecycle rule to delete tmp/ files after 90 days
  lifecycle_rule {
    condition {
      age            = 90
      matches_prefix = ["tmp/"]
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.apis]
}

# Requirement 4.6: Output bucket name
output "storage_bucket_name" {
  description = "Cloud Storage bucket name for images"
  value       = google_storage_bucket.images.name
}
