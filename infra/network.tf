# VPC Network and Private Services Access configuration
# Requirements: 2.1-2.7

# Requirement 2.1: Create custom VPC network
resource "google_compute_network" "vpc" {
  name                    = "minna-senshuken-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

# Requirements 2.2, 2.3: Create subnet in asia-northeast1 with /24 range
resource "google_compute_subnetwork" "subnet" {
  name          = "minna-senshuken-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Requirement 2.4: Reserve IP range for Private Services Access
resource "google_compute_global_address" "psa_range" {
  name          = "google-managed-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc.id
}

# Requirement 2.5: Establish Private Services Connection using Service Networking API
# Requirement 2.7: Error handling is automatic via Terraform
resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_range.name]
}

# Requirement 2.6: Output VPC network name and subnet name
output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}
