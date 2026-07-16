# ==============================================================================
# Outputs
# ==============================================================================

# ------------------------------------------------------------------------------
# Instance Outputs
# ------------------------------------------------------------------------------

output "instance_id" {
  description = "ID of the created instance"
  value       = module.instana_agent.instance_id
}

output "instance_name" {
  description = "Name of the created instance"
  value       = module.instana_agent.instance_name
}

output "zone" {
  description = "Zone where instance is deployed"
  value       = module.instana_agent.zone
}

output "internal_ip" {
  description = "Internal IP address"
  value       = module.instana_agent.internal_ip
}

output "external_ip" {
  description = "External IP address"
  value       = module.instana_agent.external_ip
}

output "service_account_email" {
  description = "Service account email used by the instance"
  value       = module.instana_agent.service_account_email
}

# ------------------------------------------------------------------------------
# Instana Configuration Outputs
# ------------------------------------------------------------------------------

output "instana_endpoint" {
  description = "Instana endpoint configured for the agent"
  value       = module.instana_agent.instana_endpoint
}

output "instana_agent_mode" {
  description = "Instana agent mode configured"
  value       = module.instana_agent.instana_agent_mode
}

# ------------------------------------------------------------------------------
# GCP Monitoring Outputs
# ------------------------------------------------------------------------------

output "gcp_monitoring_project_id" {
  description = "GCP project ID being monitored by Instana"
  value       = module.instana_agent.gcp_monitoring_project_id
}

output "gcp_credentials_path" {
  description = "Path where GCP credentials are stored on the agent host"
  value       = module.instana_agent.gcp_credentials_path
}

output "gcp_monitoring_configuration" {
  description = "GCP monitoring configuration summary"
  value       = module.instana_agent.gcp_monitoring_configuration
}

output "gcp_configuration_yaml_path" {
  description = "Path to configuration.yaml on the agent host"
  value       = module.instana_agent.gcp_configuration_yaml_path
}

# ------------------------------------------------------------------------------
# Operational Outputs
# ------------------------------------------------------------------------------

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = module.instana_agent.ssh_command
}

output "agent_status_command" {
  description = "Command to check agent status"
  value       = module.instana_agent.agent_status_command
}

output "agent_logs_command" {
  description = "Command to view installation logs"
  value       = module.instana_agent.agent_logs_command
}

output "agent_runtime_logs_command" {
  description = "Command to view agent runtime logs"
  value       = module.instana_agent.agent_runtime_logs_command
}

output "verify_gcp_monitoring_command" {
  description = "Command to verify GCP monitoring configuration on the agent host"
  value       = module.instana_agent.verify_gcp_monitoring_command
}
