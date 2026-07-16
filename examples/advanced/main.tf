# ==============================================================================
# Advanced Example - Instana Agent for GCP Remote Monitoring
# ==============================================================================
#
# This example demonstrates production-ready configuration including:
# - Custom machine type and SSD disk
# - Dedicated service account for the VM
# - Instana zone for logical grouping
# - GCP monitoring plugin with tag filtering
# - Custom labels and network tags
# - Custom agent memory for large environments
# - Custom configuration file (optional)
#
# Prerequisites:
# 1. Create a GCP service account with required monitoring permissions:
#    - monitoring.timeSeries.list
#    - pubsub.subscriptions.list
#    - pubsub.topics.list
#    - resourcemanager.projects.get
#    - cloudsql.instances.list
#    - storage.buckets.list
# 2. Download the service account JSON key file from GCP Console
# 3. Store the key file securely (do not commit to version control)
#

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Deploy Instana agent with advanced / production configuration
module "instana_agent" {
  source = "../../"

  # GCP Project to Monitor
  project_id    = var.project_id
  instance_name = var.instance_name
  zone          = var.zone

  # Instana Backend Configuration
  instana_endpoint_host = var.instana_endpoint_host
  instana_endpoint_port = var.instana_endpoint_port
  instana_agent_key     = var.instana_agent_key
  instana_download_key  = var.instana_download_key
  instana_agent_mode    = var.instana_agent_mode

  # GCP Monitoring Configuration
  # Path to your pre-existing service account JSON key file
  gcp_service_account_key_file = var.gcp_service_account_key_file

  # Where credentials are placed on the agent host
  gcp_credentials_path = var.gcp_credentials_path

  # Custom configuration appended to configuration.yaml on the agent host.
  # Contains the com.instana.plugin.gcp block with poll_rate, include/exclude tags.
  # Copy custom-config.yaml.example to custom-config.yaml and set the path below.
  custom_configuration_file = var.custom_configuration_file

  # Agent memory — increase for large environments
  agent_max_memory = var.agent_max_memory

  # Instance configuration
  machine_type      = var.machine_type
  boot_disk_size_gb = var.boot_disk_size_gb
  boot_disk_type    = var.boot_disk_type
  image_family      = var.image_family
  image_project     = var.image_project

  # Network configuration
  network          = var.network
  subnetwork       = var.subnetwork
  enable_public_ip = var.enable_public_ip
  tags             = var.tags

  # Deployment mode
  manage_instance = var.manage_instance

  # Create a dedicated service account for the VM
  create_service_account = var.create_service_account

  # Labels and update behaviour
  labels                    = var.labels
  allow_stopping_for_update = var.allow_stopping_for_update
}
