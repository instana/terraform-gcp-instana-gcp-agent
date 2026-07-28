# ==============================================================================
# Basic Example - Instana Agent for GCP Remote Monitoring
# ==============================================================================
#
# This example demonstrates the minimal configuration required to deploy
# an Instana agent for monitoring GCP resources.
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

# Deploy Instana agent for GCP monitoring
module "instana_agent" {
  source  = "instana/instana-gcp-agent/gcp"
  version = "1.0.0" # Replace with desired version

  # GCP Project to Monitor
  project_id    = var.project_id
  instance_name = var.instance_name
  zone          = var.zone

  # Instana Backend Configuration
  instana_endpoint_host = var.instana_endpoint_host
  instana_agent_key     = var.instana_agent_key
  instana_download_key  = var.instana_download_key
  instana_agent_mode    = var.instana_agent_mode

  # GCP Monitoring Configuration
  # Path to your pre-existing service account JSON key file
  gcp_service_account_key_file = var.gcp_service_account_key_file

  # Custom configuration appended to configuration.yaml on the agent host.
  # Contains the com.instana.plugin.gcp block with poll_rate, include/exclude tags.
  # Copy custom-config.yaml.example to custom-config.yaml and set the path below.
  custom_configuration_file = var.custom_configuration_file

  # Optional: Instance configuration
  machine_type = var.machine_type

  # Optional: Increase agent memory for large environments
  # agent_max_memory = 1024

  # Optional: Add labels to the instance
  labels = {
    environment = "development"
    managed_by  = "terraform"
    example     = "basic"
    purpose     = "gcp-monitoring"
  }
}