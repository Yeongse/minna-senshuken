# Cloud SQL for MySQL configuration
# Requirements: 3.1-3.9, 11.1

# Requirement 3.7: Generate secure password
resource "random_password" "db_password" {
  length  = 32
  special = false
}

# Requirements 3.1-3.6, 3.8, 3.9, 11.1
resource "google_sql_database_instance" "main" {
  name             = "minna-senshuken-db"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    # Requirement 3.1, 11.1: db-f1-micro for minimum cost
    tier = "db-f1-micro"

    # Requirement 3.3: Single zone configuration (HA disabled)
    availability_type = "ZONAL"

    # Requirement 3.2: 10GB SSD storage
    disk_size = 10
    disk_type = "PD_SSD"

    # Requirements 3.5, 3.6: Private VPC connection, no public IP
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }

    # Requirement 3.4: Auto backup enabled (daily at 03:00, 7 days retention)
    backup_configuration {
      enabled            = true
      start_time         = "03:00"
      binary_log_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }
  }

  # Set to true in production
  deletion_protection = false

  # Depends on Private Services Access connection
  depends_on = [google_service_networking_connection.psa]
}

# Requirement 3.7: Create application database
resource "google_sql_database" "app" {
  name     = "minna_senshuken"
  instance = google_sql_database_instance.main.name
}

# Requirement 3.7: Create application user
resource "google_sql_user" "app" {
  name     = "app"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

# Requirement 3.8: Output instance name and private IP
output "database_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.main.name
}

output "database_private_ip" {
  description = "Cloud SQL private IP address"
  value       = google_sql_database_instance.main.private_ip_address
  sensitive   = true
}
