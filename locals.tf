# ==============================================================================
# Local Values
# ==============================================================================

locals {
  # Determine service account email to use
  service_account_email = var.manage_instance ? (
    var.create_service_account ? (
      google_service_account.instana_agent[0].email
      ) : (
      var.service_account_email != null ?
      var.service_account_email :
      "${data.google_project.current.number}-compute@developer.gserviceaccount.com"
    )
  ) : null

  # Construct Instana endpoint
  instana_endpoint = "${var.instana_endpoint_host}:${var.instana_endpoint_port}"

  # Target instance identity (same for both managed and existing VM modes)
  target_instance_name       = var.instance_name
  target_instance_zone       = var.zone
  target_instance_project_id = var.project_id

  # ==============================================================================
  # GCP Monitoring Configuration
  # ==============================================================================

  # Read the GCP service account key file content (empty string when no key file is provided)
  gcp_key_content = var.gcp_service_account_key_file != null ? data.local_file.gcp_service_account_key[0].content : ""

  # Base64 encode the key file for secure transfer
  gcp_key_base64 = local.gcp_key_content != "" ? base64encode(local.gcp_key_content) : ""

  # Read custom configuration file if provided
  custom_config_content = var.custom_configuration_file != null ? file(var.custom_configuration_file) : ""

  # Base64 encode the custom configuration for secure transfer
  custom_config_base64 = var.custom_configuration_file != null ? base64encode(local.custom_config_content) : ""

  # Metadata for startup script (including GCP monitoring config)
  startup_script_metadata = {
    INSTANA_AGENT_KEY     = var.instana_agent_key
    INSTANA_DOWNLOAD_KEY  = var.instana_download_key
    INSTANA_ENDPOINT_HOST = var.instana_endpoint_host
    INSTANA_ENDPOINT_PORT = tostring(var.instana_endpoint_port)
    INSTANA_AGENT_MODE    = var.instana_agent_mode
    AGENT_MAX_MEM         = "${var.agent_max_memory}M"
    GCP_KEY_BASE64        = local.gcp_key_base64
    GCP_CREDENTIALS_PATH  = var.gcp_credentials_path
    GCP_PROJECT_ID        = var.project_id
    CUSTOM_CONFIG_BASE64  = local.custom_config_base64
  }

  # Rendered installation script for existing VM mode
  existing_vm_install_script = <<-EOT
#!/bin/bash
export INSTANA_AGENT_KEY='${replace(var.instana_agent_key, "'", "'\"'\"'")}'
export INSTANA_DOWNLOAD_KEY='${replace(var.instana_download_key, "'", "'\"'\"'")}'
export INSTANA_ENDPOINT_HOST='${replace(var.instana_endpoint_host, "'", "'\"'\"'")}'
export INSTANA_ENDPOINT_PORT='${var.instana_endpoint_port}'
export INSTANA_AGENT_MODE='${replace(var.instana_agent_mode, "'", "'\"'\"'")}'
export AGENT_MAX_MEM='${var.agent_max_memory}M'
export GCP_KEY_BASE64='${local.gcp_key_base64}'
export GCP_CREDENTIALS_PATH='${var.gcp_credentials_path}'
export GCP_PROJECT_ID='${var.project_id}'
export CUSTOM_CONFIG_BASE64='${local.custom_config_base64}'

${file("${path.module}/startup-script.sh")}
EOT

  existing_vm_install_command = <<-EOT
    gcloud compute ssh ${local.target_instance_name} \
      --zone=${local.target_instance_zone} \
      --project=${local.target_instance_project_id} \
      --command='sudo bash -s' <<'SCRIPT_EOF'
    ${local.existing_vm_install_script}
    SCRIPT_EOF
  EOT
}