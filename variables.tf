# ==============================================================================
# Required Variables
# ==============================================================================

variable "project_id" {
  description = "GCP project ID to monitor. The Instana agent can monitor only a single GCP project at a time."
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty."
  }
}

# ==============================================================================
# GCP Monitoring Configuration Variables
# ==============================================================================

variable "gcp_service_account_key_file" {
  description = <<-EOT
    Path to the GCP service account JSON key file. This file must be a valid JSON key file
    downloaded from GCP Console. The service account must have the following minimum permissions:
    - monitoring.timeSeries.list
    - pubsub.subscriptions.list
    - pubsub.topics.list
    - resourcemanager.projects.get
    - cloudsql.instances.list
    - storage.buckets.list
    
    Example: "/path/to/service-account-key.json"
  EOT
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.gcp_service_account_key_file == null || can(regex("\\.(json|JSON)$", var.gcp_service_account_key_file))
    error_message = "Service account key file must be a JSON file with .json extension."
  }
}

variable "gcp_credentials_path" {
  description = <<-EOT
    Path where the GCP service account key file will be stored on the Instana agent host.
    This path will be referenced in the configuration.yaml file.
    
    Default: "/opt/instana/agent/etc/instana/gcp-credentials.json"
  EOT
  type        = string
  default     = "/opt/instana/agent/etc/instana/gcp-credentials.json"
}

variable "custom_configuration_file" {
  description = <<-EOT
    Path to a custom configuration.yaml file to append to the Instana agent configuration.
    This file content will be appended to the agent's configuration.yaml file.
    Leave empty to skip custom configuration.
    
    Example: "/path/to/custom-config.yaml"
  EOT
  type        = string
  default     = null
}

variable "agent_max_memory" {
  description = <<-EOT
    Maximum memory allocation for the Instana agent in MB.
    Increase this value if monitoring a large number of GCP resources.
    
    Default: 544 MB
    Recommended for large environments: 1024 MB or higher
  EOT
  type        = number
  default     = 544

  validation {
    condition     = var.agent_max_memory >= 512 && var.agent_max_memory <= 8192
    error_message = "Agent max memory must be between 512 and 8192 MB."
  }
}

variable "instance_name" {
  description = "Name of the compute instance"
  type        = string

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{0,61}[a-z0-9]$", var.instance_name))
    error_message = "Instance name must be lowercase, start with a letter, and contain only letters, numbers, and hyphens (max 63 characters)."
  }
}

variable "zone" {
  description = "GCP zone for the instance (e.g., us-central1-a)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", var.zone))
    error_message = "Zone must be a valid GCP zone format (e.g., us-central1-a)."
  }
}

variable "instana_endpoint_host" {
  description = "Instana backend endpoint host (e.g., ingress-pink-saas.instana.rocks)"
  type        = string

  validation {
    condition     = length(var.instana_endpoint_host) > 0
    error_message = "Instana endpoint host cannot be empty."
  }
}

variable "instana_agent_key" {
  description = "Instana agent key for authentication"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.instana_agent_key) > 0
    error_message = "Instana agent key cannot be empty."
  }
}

variable "instana_download_key" {
  description = "Instana download key for agent installation"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.instana_download_key) > 0
    error_message = "Instana download key cannot be empty."
  }
}

# ==============================================================================
# Optional Variables - Instana Configuration
# ==============================================================================

variable "instana_endpoint_port" {
  description = "Instana backend endpoint port"
  type        = number
  default     = 443

  validation {
    condition     = var.instana_endpoint_port > 0 && var.instana_endpoint_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "instana_agent_mode" {
  description = "Instana agent mode (APM, INFRASTRUCTURE, AWS, KUBERNETES, dynamic)"
  type        = string
  default     = "dynamic"

  validation {
    condition     = contains(["APM", "INFRASTRUCTURE", "AWS", "KUBERNETES", "dynamic"], var.instana_agent_mode)
    error_message = "Agent mode must be one of: APM, INFRASTRUCTURE, AWS, KUBERNETES, dynamic."
  }
}


# ==============================================================================
# Optional Variables - Instance Configuration
# ==============================================================================

variable "machine_type" {
  description = "GCP machine type for the instance"
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.boot_disk_size_gb >= 10 && var.boot_disk_size_gb <= 65536
    error_message = "Boot disk size must be between 10 and 65536 GB."
  }
}

variable "boot_disk_type" {
  description = "Boot disk type (pd-standard, pd-balanced, pd-ssd)"
  type        = string
  default     = "pd-balanced"

  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd"], var.boot_disk_type)
    error_message = "Boot disk type must be one of: pd-standard, pd-balanced, pd-ssd."
  }
}

variable "image_family" {
  description = "OS image family (debian-11, debian-12, ubuntu-2004-lts, ubuntu-2204-lts)"
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
  description = "VPC network name. Use 'default' for default network."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork name (required for custom networks, leave null for default network)"
  type        = string
  default     = null
}

variable "enable_public_ip" {
  description = "Assign external IP address to the instance. Required for the agent to reach setup.instana.io and the Instana backend unless Cloud NAT is configured on the VPC."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Network tags for the instance (used for firewall rules)"
  type        = list(string)
  default     = ["instana-agent"]

  validation {
    condition     = length(var.tags) > 0
    error_message = "At least one network tag must be specified."
  }
}

# ==============================================================================
# Optional Variables - Deployment Mode and Service Account
# ==============================================================================

variable "manage_instance" {
  description = "Whether this module should create and manage the compute instance. Set to false to install the Instana agent on an existing VM using generated commands."
  type        = bool
  default     = true
}


variable "create_service_account" {
  description = "Create a dedicated service account for the managed instance. Ignored when manage_instance is false."
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Service account email to use for the managed instance (if not creating new one). If null, uses default compute service account. Ignored when manage_instance is false."
  type        = string
  default     = null
}

# ==============================================================================
# Optional Variables - Labels and Metadata
# ==============================================================================

variable "labels" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default = {
    managed_by = "terraform"
    monitoring = "instana"
  }
}

variable "allow_stopping_for_update" {
  description = "Allow instance to be stopped for updates"
  type        = bool
  default     = true
}

variable "use_iap_tunnel" {
  description = <<-EOT
    Use IAP tunnel for SSH connection instead of direct SSH (when manage_instance = false).
    Requires gcloud to be configured with appropriate IAP permissions.
    When true, no external IP is required on the VM.
  EOT
  type        = bool
  default     = false
}

variable "use_gcloud_ssh" {
  description = <<-EOT
    Use gcloud compute ssh for connecting to existing VM (when manage_instance = false).
    This is the recommended approach as it handles authentication automatically.
    When true, ssh_user and ssh_private_key_path are ignored.
  EOT
  type        = bool
  default     = true
}