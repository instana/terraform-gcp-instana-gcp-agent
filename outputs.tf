# ==============================================================================
# Instance Outputs
# ==============================================================================

output "instance_id" {
  description = "ID of the created compute instance"
  value       = var.manage_instance ? google_compute_instance.instana_agent[0].id : null
}

output "instance_name" {
  description = "Name of the target compute instance"
  value       = local.target_instance_name
}

output "instance_self_link" {
  description = "Self-link of the created compute instance"
  value       = var.manage_instance ? google_compute_instance.instana_agent[0].self_link : null
}

output "zone" {
  description = "Zone of the target instance"
  value       = local.target_instance_zone
}

# ==============================================================================
# Network Outputs
# ==============================================================================

output "internal_ip" {
  description = "Internal IP address of the created instance"
  value       = var.manage_instance ? google_compute_instance.instana_agent[0].network_interface[0].network_ip : null
}

output "external_ip" {
  description = "External IP address of the created instance (if enabled)"
  value       = var.manage_instance ? try(google_compute_instance.instana_agent[0].network_interface[0].access_config[0].nat_ip, null) : null
}

# ==============================================================================
# Service Account Output
# ==============================================================================

output "service_account_email" {
  description = "Service account email used by the managed instance"
  value       = local.service_account_email
}

# ==============================================================================
# Instana Configuration Outputs
# ==============================================================================

output "instana_endpoint" {
  description = "Instana endpoint configured for the agent"
  value       = local.instana_endpoint
}

output "instana_agent_mode" {
  description = "Instana agent mode configured"
  value       = var.instana_agent_mode
}

# ==============================================================================
# GCP Monitoring Outputs
# ==============================================================================

output "gcp_monitoring_project_id" {
  description = "GCP project ID being monitored by Instana"
  value       = var.project_id
}

output "gcp_credentials_path" {
  description = "Path where GCP service account credentials are stored on the agent host"
  value       = var.gcp_credentials_path
}

output "gcp_monitoring_configuration" {
  description = "GCP monitoring configuration summary"
  value = {
    project_id       = var.project_id
    credentials_path = var.gcp_credentials_path
    agent_max_memory = "${var.agent_max_memory}M"
  }
}

# ==============================================================================
# Operational Outputs
# ==============================================================================

output "ssh_command" {
  description = "Command to SSH into the target instance using gcloud"
  value       = "gcloud compute ssh ${local.target_instance_name} --zone=${local.target_instance_zone} --project=${local.target_instance_project_id}"
}

output "agent_status_command" {
  description = "Command to check Instana agent status on the target instance"
  value       = "gcloud compute ssh ${local.target_instance_name} --zone=${local.target_instance_zone} --project=${local.target_instance_project_id} --command='sudo systemctl status instana-agent'"
}

output "agent_logs_command" {
  description = "Command to view agent installation logs on the target instance"
  value       = "gcloud compute ssh ${local.target_instance_name} --zone=${local.target_instance_zone} --project=${local.target_instance_project_id} --command='sudo cat /var/log/instana-agent-install.log'"
}

output "agent_runtime_logs_command" {
  description = "Command to view agent runtime logs on the target instance"
  value       = "gcloud compute ssh ${local.target_instance_name} --zone=${local.target_instance_zone} --project=${local.target_instance_project_id} --command='sudo tail -f /opt/instana/agent/data/log/agent.log'"
}

output "existing_vm_install_script" {
  description = "Rendered installation script for manually installing the Instana agent on an existing VM when manage_instance is false."
  value       = var.manage_instance ? null : local.existing_vm_install_script
  sensitive   = true
}

output "existing_vm_install_command" {
  description = "gcloud command to install the Instana agent on an existing VM when manage_instance is false."
  value       = var.manage_instance ? null : local.existing_vm_install_command
  sensitive   = true
}

output "gcp_configuration_yaml_path" {
  description = "Path to the configuration.yaml file on the agent host containing GCP monitoring settings"
  value       = "/opt/instana/agent/etc/instana/configuration.yaml"
}

output "verify_gcp_monitoring_command" {
  description = "Command to verify GCP monitoring configuration on the agent host"
  value       = "gcloud compute ssh ${local.target_instance_name} --zone=${local.target_instance_zone} --project=${local.target_instance_project_id} --command='sudo cat /opt/instana/agent/etc/instana/configuration.yaml | grep -A 5 com.instana.plugin.gcp'"
}