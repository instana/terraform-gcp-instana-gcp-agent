# ==============================================================================
# Instana Agent Script Module
# ==============================================================================


module "instana_agent_script" {
  source = "instana/instana-agent-script/instana"
  version = ">= 1.0.0"

  instana_agent_key     = var.instana_agent_key
  instana_download_key  = var.instana_download_key
  instana_endpoint_host = var.instana_endpoint_host
  instana_endpoint_port = var.instana_endpoint_port
  instana_agent_mode    = var.instana_agent_mode
  agent_max_memory      = var.agent_max_memory
  custom_config_yaml = local.custom_config_content != "" ? local.custom_config_content : null
}

# ==============================================================================
# GCP Remote Monitoring with Instana
# ==============================================================================
# This module deploys an Instana agent for monitoring GCP resources.
# Customers must provide their own pre-existing service account key file
# with the required monitoring permissions.
#
# Required GCP Service Account Permissions:
# - monitoring.timeSeries.list
# - pubsub.subscriptions.list
# - pubsub.topics.list
# - resourcemanager.projects.get
# - cloudsql.instances.list
# - storage.buckets.list
# ==============================================================================

# ==============================================================================
# Service Account (Optional - for Compute Instance only)
# ==============================================================================
# Note: This service account is ONLY for the Compute Engine instance running
# the Instana agent. It is NOT the monitoring service account.
# The monitoring service account key must be provided via gcp_service_account_key_file.

resource "google_service_account" "instana_agent" {
  count = var.manage_instance && var.create_service_account ? 1 : 0

  account_id   = "${var.instance_name}-sa"
  display_name = "Service Account for ${var.instance_name}"
  description  = "Managed by Terraform for Instana agent instance"
  project      = var.project_id
}

# ==============================================================================
# Compute Engine Instance
# ==============================================================================

resource "google_compute_instance" "instana_agent" {
  count        = var.manage_instance ? 1 : 0
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags   = var.tags
  labels = var.labels

  allow_stopping_for_update = var.allow_stopping_for_update

  # Boot disk configuration
  boot_disk {
    initialize_params {
      image = data.google_compute_image.os_image.self_link
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  # Network configuration
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    # Conditionally add external IP
    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {
        # Ephemeral public IP
      }
    }
  }

  # Service account configuration
  service_account {
    email = local.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  metadata = local.startup_script_metadata

  # Lifecycle configuration
  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }
}

# ==============================================================================
# Remote Execution for Existing VM
# ==============================================================================

# Execute installation on existing VM using gcloud SSH
resource "null_resource" "install_on_existing_vm_gcloud" {
  count = (!var.manage_instance && var.use_gcloud_ssh) ? 1 : 0

  # Trigger re-execution when configuration changes
  triggers = {
    script_hash      = sha256(local.existing_vm_install_script)
    instance_name    = local.target_instance_name
    instance_zone    = local.target_instance_zone
    instance_project = local.target_instance_project_id
    use_iap_tunnel   = var.use_iap_tunnel
    instana_endpoint = local.instana_endpoint
    agent_mode       = var.instana_agent_mode
    gcp_key_hash     = sha256(local.gcp_key_content)
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Installing Instana agent on existing VM: ${local.target_instance_name}"
      printf '%s' '${base64encode(local.existing_vm_install_script)}' \
        | base64 -d \
        | gcloud compute ssh ${local.target_instance_name} \
            --zone=${local.target_instance_zone} \
            --project=${local.target_instance_project_id} \
            ${var.use_iap_tunnel ? "--tunnel-through-iap" : ""} \
            --command='sudo bash -s'
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Uninstalling Instana agent from existing VM: ${self.triggers.instance_name}"
      gcloud compute ssh ${self.triggers.instance_name} \
        --zone=${self.triggers.instance_zone} \
        --project=${self.triggers.instance_project} \
        ${self.triggers.use_iap_tunnel == "true" ? "--tunnel-through-iap" : ""} \
        --command='sudo systemctl stop instana-agent || true && \
                   sudo apt remove -y instana-agent || true && \
                   sudo rm -rf /opt/instana || true && \
                   sudo rm -rf /var/lib/instana || true && \
                   sudo rm -f /etc/apt/sources.list.d/instana.list || true'
    EOT
  }

  depends_on = [data.google_compute_instance.existing]
}
