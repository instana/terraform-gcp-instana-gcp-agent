# ==============================================================================
# Data Sources
# ==============================================================================

# Get current project information
data "google_project" "current" {
  project_id = var.project_id
}

# Get the latest OS image
data "google_compute_image" "os_image" {
  family  = var.image_family
  project = var.image_project
}

# ==============================================================================
# GCP Monitoring Data Sources
# ==============================================================================

# Verify the GCP service account key file exists (only when a path is provided)
data "local_file" "gcp_service_account_key" {
  count    = var.gcp_service_account_key_file != null ? 1 : 0
  filename = var.gcp_service_account_key_file
}

# ==============================================================================
# Existing VM Data Source
# ==============================================================================

# Fetch existing VM details when manage_instance = false
data "google_compute_instance" "existing" {
  count   = var.manage_instance ? 0 : 1
  name    = var.instance_name
  zone    = var.zone
  project = var.project_id
}