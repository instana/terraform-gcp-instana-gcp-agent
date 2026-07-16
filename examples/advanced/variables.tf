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
  default     = "instana-agent-advanced"
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
  default     = null
}

variable "gcp_credentials_path" {
  description = "Path where the GCP service account key file will be stored on the agent host"
  type        = string
  default     = "/opt/instana/agent/etc/instana/gcp-credentials.json"
}

variable "agent_max_memory" {
  description = "Maximum memory for the Instana agent in MB"
  type        = number
  default     = 1024
}

variable "custom_configuration_file" {
  description = "Path to a custom configuration.yaml snippet to append to the agent config (optional)"
  type        = string
  default     = null
}

# ==============================================================================
# Optional Variables - Instana Configuration
# ==============================================================================

variable "instana_endpoint_port" {
  description = "Instana backend endpoint port"
  type        = number
  default     = 443
}

variable "instana_agent_mode" {
  description = "Instana agent mode"
  type        = string
  default     = "dynamic"
}

# ==============================================================================
# Optional Variables - Instance Configuration
# ==============================================================================

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-ssd"
}

variable "image_family" {
  description = "OS image family"
  type        = string
  default     = "debian-11"
}

variable "image_project" {
  description = "Project containing the OS image"
  type        = string
  default     = "debian-cloud"
}

# ==============================================================================
# Optional Variables - Network Configuration
# ==============================================================================

variable "network" {
  description = "VPC network name"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork name (null = auto-select for the chosen network)"
  type        = string
  default     = null
}

variable "enable_public_ip" {
  description = "Assign external IP address"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Network tags"
  type        = list(string)
  default     = ["instana-agent", "monitoring", "production"]
}

# ==============================================================================
# Optional Variables - Deployment Mode
# ==============================================================================

variable "manage_instance" {
  description = "Whether this module should create and manage the compute instance"
  type        = bool
  default     = true
}

# ==============================================================================
# Optional Variables - Service Account
# ==============================================================================

variable "create_service_account" {
  description = "Create a dedicated service account for the VM"
  type        = bool
  default     = true
}

# ==============================================================================
# Optional Variables - Labels and Update Behaviour
# ==============================================================================

variable "labels" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default = {
    managed_by  = "terraform"
    monitoring  = "instana"
    environment = "production"
    team        = "platform"
  }
}

variable "allow_stopping_for_update" {
  description = "Allow instance to be stopped for updates"
  type        = bool
  default     = true
}
