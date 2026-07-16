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

  # ==============================================================================
  # Startup script
  # ==============================================================================

  startup_script_content = file("${path.module}/startup-script.sh")
  startup_script_metadata = {
    # Non-secret configuration
    INSTANA_ENDPOINT_HOST = var.instana_endpoint_host
    INSTANA_ENDPOINT_PORT = tostring(var.instana_endpoint_port)
    INSTANA_AGENT_MODE    = var.instana_agent_mode
    AGENT_MAX_MEM         = "${var.agent_max_memory}M"
    GCP_CREDENTIALS_PATH  = var.gcp_credentials_path
    GCP_PROJECT_ID        = var.project_id
    CUSTOM_CONFIG_BASE64  = local.custom_config_base64

    # Sensitive values — these are the only metadata keys that carry secrets;
    # they are cleared by the startup script after use (unset at end of script).
    INSTANA_AGENT_KEY    = var.instana_agent_key
    INSTANA_DOWNLOAD_KEY = var.instana_download_key
    GCP_KEY_BASE64       = local.gcp_key_base64

    startup-script = local.startup_script_content
  }

  # ==============================================================================
  # Existing-VM install script / command  (manage_instance = false path)
  # ==============================================================================

  existing_vm_install_script = <<-SCRIPT
#!/bin/bash
export INSTANA_AGENT_KEY=${base64encode(var.instana_agent_key)}
export INSTANA_DOWNLOAD_KEY=${base64encode(var.instana_download_key)}
export INSTANA_ENDPOINT_HOST=${base64encode(var.instana_endpoint_host)}
export INSTANA_ENDPOINT_PORT='${var.instana_endpoint_port}'
export INSTANA_AGENT_MODE=${base64encode(var.instana_agent_mode)}
export AGENT_MAX_MEM='${var.agent_max_memory}M'
export GCP_KEY_BASE64='${local.gcp_key_base64}'
export GCP_CREDENTIALS_PATH=${base64encode(var.gcp_credentials_path)}
export GCP_PROJECT_ID=${base64encode(var.project_id)}
export CUSTOM_CONFIG_BASE64='${local.custom_config_base64}'

# Decode base64-encoded string variables that may contain special characters
INSTANA_AGENT_KEY=$(printf '%s' "$INSTANA_AGENT_KEY" | base64 -d)
INSTANA_DOWNLOAD_KEY=$(printf '%s' "$INSTANA_DOWNLOAD_KEY" | base64 -d)
INSTANA_ENDPOINT_HOST=$(printf '%s' "$INSTANA_ENDPOINT_HOST" | base64 -d)
INSTANA_AGENT_MODE=$(printf '%s' "$INSTANA_AGENT_MODE" | base64 -d)
GCP_CREDENTIALS_PATH=$(printf '%s' "$GCP_CREDENTIALS_PATH" | base64 -d)
GCP_PROJECT_ID=$(printf '%s' "$GCP_PROJECT_ID" | base64 -d)

${local.startup_script_content}
SCRIPT

  existing_vm_install_command = "echo '${base64encode(local.existing_vm_install_script)}' | base64 -d | gcloud compute ssh ${local.target_instance_name} --zone=${local.target_instance_zone} --project=${local.target_instance_project_id} --command='sudo bash -s'"
}