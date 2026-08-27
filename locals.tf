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

  # ==============================================================================
  # GCP setup shell block
  #
  # Spliced into the final startup script BEFORE the upstream module's "exit 0".
  # It:
  #   1. Writes the GCP service account key file to the VM filesystem.
  #   2. Uses a Perl in-place patch to overwrite credentials_path in every
  #      com.instana.plugin.gcp* section of configuration.yaml — regardless of
  #      whether the current value is blank, '', "", or an existing path.
  #
  # Empty string when no key is provided — completely skipped for non-GCP use.
  # ==============================================================================

  gcp_setup_block = join("", local.gcp_key_base64 != "" ? [
    "\n",
    "# ==============================================================================\n",
    "# GCP Service Account Credentials Setup (injected by terraform-gcp-instana-agent)\n",
    "# ==============================================================================\n",
    "\n",
    "log \"Setting up GCP service account credentials...\"\n",
    "GCP_CREDS_PATH=\"${var.gcp_credentials_path}\"\n",
    "GCP_CREDS_DIR=$(dirname \"$GCP_CREDS_PATH\")\n",
    "mkdir -p \"$GCP_CREDS_DIR\" && chmod 755 \"$GCP_CREDS_DIR\"\n",
    "printf '%s' '${local.gcp_key_base64}' | base64 -d > \"$GCP_CREDS_PATH\"\n",
    "chmod 600 \"$GCP_CREDS_PATH\"\n",
    "log \"GCP credentials written to $GCP_CREDS_PATH\"\n",
    "\n",
    "# Patch credentials_path (any value: blank, '', \"\", or existing path) in every com.instana.plugin.gcp* section\n",
    "CONFIG_FILE=\"/opt/instana/agent/etc/instana/configuration.yaml\"\n",
    "if [ -f \"$CONFIG_FILE\" ]; then\n",
    "  CREDS_PATH=\"$GCP_CREDS_PATH\" perl -i -pe '\n",
    "    BEGIN { $creds = $ENV{CREDS_PATH}; }\n",
    "    if (/^com\\.instana\\.plugin\\.gcp/) { $in_gcp = 1; }\n",
    "    elsif ($in_gcp && /^[^\\s#]/ && !/^com\\.instana\\.plugin\\.gcp/) { $in_gcp = 0; }\n",
    "    if ($in_gcp && /^\\s+credentials_path:/) {\n",
    "      s|^(\\s*)credentials_path:.*|$1credentials_path: '\"'\"'$creds'\"'\"'|;\n",
    "    }\n",
    "  ' \"$CONFIG_FILE\"\n",
    "  log \"GCP credentials_path updated in all com.instana.plugin.gcp* sections\"\n",
    "fi\n",
    "\n",
    "unset GCP_CREDS_PATH GCP_CREDS_DIR\n",
  ] : [])

  # ==============================================================================
  # Startup script
  # ==============================================================================

  # The upstream module's script ends with "exit 0". Strip it, splice in the
  # GCP setup block, then re-add "exit 0" so the block runs before the process exits.
  startup_script_content = join("\n", [
    replace(trimspace(module.instana_agent_script.linux_agent_bootstrap), "/\\nexit 0\\s*$/", ""),
    local.gcp_setup_block,
    "exit 0",
  ])

  startup_script_metadata = {
    startup-script = local.startup_script_content
  }

  # ==============================================================================
  # Existing-VM install script / command  (manage_instance = false path)
  # ==============================================================================

  existing_vm_install_script = local.startup_script_content

  existing_vm_install_command = "echo '${base64encode(local.existing_vm_install_script)}' | base64 -d | gcloud compute ssh ${local.target_instance_name} --zone=${local.target_instance_zone} --project=${local.target_instance_project_id} --command='sudo bash -s'"
}