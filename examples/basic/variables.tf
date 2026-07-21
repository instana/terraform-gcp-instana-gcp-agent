# ==============================================================================
# Required Variables
# ==============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name of the compute instance"
  type        = string
  default     = "instana-agent-basic"
}

variable "instana_endpoint_host" {
  description = "Instana backend endpoint host"
  type        = string
}

variable "instana_agent_key" {
  description = "Instana agent key"
  type        = string
  sensitive   = true
}

variable "instana_download_key" {
  description = "Instana download key"
  type        = string
  sensitive   = true
}

# ==============================================================================
# GCP Monitoring Variables
# ==============================================================================

variable "gcp_service_account_key_file" {
  description = "Path to the GCP service account JSON key file for monitoring"
  type        = string
}

# ==============================================================================
# Optional Variables
# ==============================================================================

variable "custom_configuration_file" {
  description = "Path to a custom configuration.yaml snippet to append to the agent config (optional)"
  type        = string
  default     = null
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-medium"
}

variable "instana_agent_mode" {
  description = "Instana agent mode"
  type        = string
  default     = "dynamic"
}