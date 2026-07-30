# Changelog

## [v1.0.1](https://github.com/instana/terraform-gcp-instana-agent/tree/v1.0.1) - 2026-07-30

### Documentation
- Added `version` pin (`1.0.0`) to all module source blocks in `README.md` and both example configurations (`examples/basic/main.tf`, `examples/advanced/main.tf`)
- Updated module source path across README and examples

## [v1.0.0](https://github.com/instana/terraform-gcp-instana-agent/tree/v1.0.0)

### Changes
- Initial module implementation
- GCP Compute Engine instance deployment with Instana agent
- Support for monitoring GCP services: Compute Engine, Cloud SQL, GKE, Cloud Storage, Pub/Sub, and Datastore
- Customer-provided GCP service account key file for monitoring credentials
- Automated Instana agent installation via startup script
- Optional custom `configuration.yaml` append via `custom_configuration_file` variable
- Support for creating a new VM (`manage_instance = true`) or installing on an existing VM (`manage_instance = false`)
- Optional dedicated service account creation for the Compute Engine instance
- Configurable machine type, boot disk size/type, and OS image family
- Flexible network configuration: VPC network, subnetwork, and optional public IP
- IAP tunnel support for SSH access without external IP
- `gcloud compute ssh` support for existing VM deployments
- Network tags for firewall rule integration
- Configurable Instana agent mode, endpoint host/port, memory allocation
- Comprehensive outputs: instance details, SSH commands, agent log commands, monitoring config
- Sensible defaults with full customization support via input variables
- Terraform version constraint `>= 1.3.0` with Google provider `~> 5.0`
