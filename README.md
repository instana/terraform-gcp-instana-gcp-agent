# Terraform GCP Instana Agent Module

A Terraform module for deploying [Instana](https://www.instana.com/) monitoring agents on Google Cloud Platform (GCP) for **remote monitoring of GCP resources**. This module automatically discovers and monitors GCP services including Compute Engine, Cloud SQL, GKE, Cloud Storage, Pub/Sub, and Datastore.

## Features

- ✅ **GCP Remote Monitoring**: Automatically discover and monitor GCP resources
- ✅ **Multi-Service Support**: Monitor Compute Engine, Cloud SQL, GKE, Storage, Pub/Sub, Datastore
- ✅ **Customer-Provided Credentials**: Use your own pre-existing service account key files
- ✅ **Automated Configuration**: Instana agent and GCP plugin configured automatically
- ✅ **Flexible Deployment**: Create new VM or install on existing VM
- ✅ **Resource Filtering**: Include/exclude resources by labels
- ✅ **Configurable Polling**: Adjust API polling rate for your needs
- ✅ **Production-Ready**: Sensible defaults with full customization options

## Prerequisites

### 1. GCP Service Account for Monitoring

**IMPORTANT**: You must create a GCP service account with monitoring permissions and download its JSON key file **before** using this module.

#### Create Service Account

```bash
# Create service account
gcloud iam service-accounts create instana-gcp-monitoring \
  --display-name="Instana GCP Monitoring" \
  --project=YOUR_PROJECT_ID

# Grant monitoring permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:instana-gcp-monitoring@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/monitoring.viewer"

# Create and download JSON key
gcloud iam service-accounts keys create ~/instana-gcp-key.json \
  --iam-account=instana-gcp-monitoring@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

#### Required IAM Permissions

The service account must have these permissions:
- `monitoring.timeSeries.list` - Read monitoring metrics
- `pubsub.subscriptions.list` - List Pub/Sub subscriptions
- `pubsub.topics.list` - List Pub/Sub topics
- `resourcemanager.projects.get` - Get project information
- `cloudsql.instances.list` - List Cloud SQL instances
- `storage.buckets.list` - List Cloud Storage buckets

**Note**: The `roles/monitoring.viewer` role includes all required permissions.

### 2. GCP Project Requirements

1. **GCP Project** with billing enabled
2. **Required APIs** enabled:
   - Compute Engine API (`compute.googleapis.com`)
   - Cloud Monitoring API (`monitoring.googleapis.com`)
   - Cloud SQL Admin API (`sqladmin.googleapis.com`) - if monitoring Cloud SQL
   - Kubernetes Engine API (`container.googleapis.com`) - if monitoring GKE
   - Cloud Storage API (`storage.googleapis.com`) - if monitoring Storage
   - Cloud Pub/Sub API (`pubsub.googleapis.com`) - if monitoring Pub/Sub

3. **IAM Permissions** for Terraform execution:
   - `roles/compute.instanceAdmin.v1`
   - `roles/compute.networkUser`
   - `roles/iam.serviceAccountUser`

### 3. Instana Requirements

1. Valid Instana account
2. Instana agent key
3. Instana download key
4. Instana agent endpoint URL

### 4. Network Requirements

- Outbound HTTPS (443) access to:
  - `setup.instana.io` (agent download)
  - Your Instana backend endpoint
  - `monitoring.googleapis.com` (GCP Monitoring API)
  - `cloudresourcemanager.googleapis.com` (GCP Resource Manager API)

### Software Requirements

- Terraform >= 1.3.0
- Google Cloud Provider >= 5.0

## Quick Start

### 1. Create GCP Service Account (One-Time Setup)

```bash
# Create service account with monitoring permissions
gcloud iam service-accounts create instana-gcp-monitoring \
  --display-name="Instana GCP Monitoring" \
  --project=YOUR_PROJECT_ID

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:instana-gcp-monitoring@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/monitoring.viewer"

# Download JSON key file
gcloud iam service-accounts keys create ~/instana-gcp-key.json \
  --iam-account=instana-gcp-monitoring@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### 2. Basic Usage - GCP Remote Monitoring

```hcl
module "instana_agent" {
  source = "path/to/terraform-gcp-instana-agent"

  # GCP Project to Monitor
  project_id    = "my-gcp-project"
  instance_name = "instana-agent-01"
  zone          = "us-central1-a"

  # Instana Configuration
  instana_endpoint_host = "ingress-pink-saas.instana.rocks"
  instana_agent_key     = var.instana_agent_key
  instana_download_key  = var.instana_download_key

  # GCP Monitoring Configuration
  # Path to your pre-existing service account JSON key file
  gcp_service_account_key_file = "/path/to/instana-gcp-key.json"
  
  # Optional: Custom configuration file
  # custom_configuration_file = "/path/to/custom-config.yaml"
}
```

### 3. Custom Configuration (Optional)

You can provide a custom configuration file that will be appended to the agent's `configuration.yaml`:

```hcl
module "instana_agent" {
  source = "path/to/terraform-gcp-instana-agent"

  # ... other configuration ...

  # Custom configuration file
  custom_configuration_file = "/path/to/custom-config.yaml"
}
```

The custom configuration file should contain valid YAML configuration for the Instana agent. Example:

```yaml
# GCP Monitoring Configuration
com.instana.plugin.gcp:
  poll_rate: 60
  credentials_path: ''
  exclude_tags: ''
  include_tags: 'environment:production'

# Google Cloud Datastore
com.instana.plugin.gcp.datastore:
  enabled: true
  poll_rate: 60 
  credentials_path: ''
```

See [custom-config.yaml.example](custom-config.yaml.example) for a complete example.

### 4. Create terraform.tfvars

```hcl
# Copy from example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
project_id            = "your-gcp-project-id"
zone                  = "us-central1-a"
instance_name         = "instana-agent-01"
instana_endpoint_host = "your-instana-endpoint.instana.rocks"
instana_agent_key     = "your-agent-key"
instana_download_key  = "your-download-key"
```

⚠️ **Important**: Never commit `terraform.tfvars` to version control!

### 5. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 6. Verify

```bash
# Check agent status
terraform output agent_status_command | bash

# View installation logs
terraform output agent_logs_command | bash
```

## Examples

### Basic Example

Minimal configuration for development/testing:

```hcl
module "instana_agent" {
  source = "./terraform-gcp-instana-agent"

  project_id            = "my-project"
  instance_name         = "instana-agent-dev"
  zone                  = "us-central1-a"
  instana_endpoint_host = "ingress-pink-saas.instana.rocks"
  instana_agent_key     = var.instana_agent_key
  instana_download_key  = var.instana_download_key
}
```

See [examples/basic](examples/basic/) for complete example.

### Advanced Example

Production-ready configuration with all options:

```hcl
module "instana_agent" {
  source = "./terraform-gcp-instana-agent"

  # Core configuration
  project_id            = "my-project"
  instance_name         = "instana-agent-prod-01"
  zone                  = "us-central1-a"
  
  # Instance configuration
  machine_type          = "e2-standard-2"
  boot_disk_size_gb     = 50
  boot_disk_type        = "pd-ssd"
  
  # Network configuration
  network               = "custom-vpc"
  subnetwork            = "custom-subnet"
  enable_public_ip      = true
  tags                  = ["instana-agent", "monitoring", "production"]
  
  # Instana configuration
  instana_endpoint_host = "ingress-pink-saas.instana.rocks"
  instana_agent_key     = var.instana_agent_key
  instana_download_key  = var.instana_download_key
  instana_agent_mode    = "dynamic"
  
  # Service account
  create_service_account = true
  
  # Labels
  labels = {
    environment = "production"
    team        = "platform"
    managed_by  = "terraform"
  }
}
```

See [examples/advanced](examples/advanced/) for complete example.

## Deployment Modes

### Managed VM Mode (New VM)

Default mode - creates a new VM with Instana agent:
- `manage_instance = true`
- Module creates the VM
- Module attaches metadata and startup script
- Agent installs automatically on first boot

### Existing VM Mode

Install agent on an existing VM using gcloud:
- `manage_instance = false`
- Module does not create or modify the VM resource
- Module generates installation command using gcloud compute ssh
- User runs the generated command against the existing VM

Example:

```bash
terraform output -raw existing_vm_install_command | bash
```

**Installation Methods:**
- **gcloud compute ssh** : Uses your gcloud identity for authentication
- **IAP tunnel**: Add `use_iap_tunnel = true` for VMs without external IPs

Notes:
- In existing VM mode, the same `instance_name` and `zone` variables are used to identify the target VM
- Service account creation and VM creation settings are ignored when `manage_instance = false`
- The gcloud CLI must be installed and authenticated on the machine running Terraform

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `project_id` | GCP project ID | `string` |
| `instance_name` | Name of the compute instance | `string` |
| `zone` | GCP zone (e.g., us-central1-a) | `string` |
| `instana_endpoint_host` | Instana backend endpoint host | `string` |
| `instana_agent_key` | Instana agent key | `string` (sensitive) |
| `instana_download_key` | Instana download key | `string` (sensitive) |

### Optional Variables - Instance Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `machine_type` | GCP machine type | `string` | `"e2-medium"` |
| `boot_disk_size_gb` | Boot disk size in GB | `number` | `20` |
| `boot_disk_type` | Boot disk type | `string` | `"pd-balanced"` |
| `image_family` | OS image family | `string` | `"debian-11"` |
| `image_project` | Project containing OS image | `string` | `"debian-cloud"` |

### Optional Variables - Network Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `network` | VPC network name | `string` | `"default"` |
| `subnetwork` | Subnetwork name | `string` | `null` |
| `enable_public_ip` | Assign external IP address. Required for agent installation unless Cloud NAT is configured on the VPC. | `bool` | `true` |
| `tags` | Network tags | `list(string)` | `["instana-agent"]` |

### Optional Variables - Instana Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `instana_endpoint_port` | Instana endpoint port | `number` | `443` |
| `instana_agent_mode` | Agent mode (APM, INFRASTRUCTURE, etc.) | `string` | `"dynamic"` |

### Optional Variables - Deployment Mode and Service Account

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `manage_instance` | Create and manage the VM in this module | `bool` | `true` |
| `create_service_account` | Create dedicated service account for managed VM mode | `bool` | `false` |
| `service_account_email` | Existing service account email for managed VM mode | `string` | `null` |

### Optional Variables - Labels and Metadata

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `labels` | Labels to apply to instance | `map(string)` | `{managed_by = "terraform", monitoring = "instana"}` |
| `allow_stopping_for_update` | Allow stopping for updates | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | ID of the created compute instance, or `null` in existing VM mode |
| `instance_name` | Name of the target compute instance |
| `instance_self_link` | Self-link of the created compute instance, or `null` in existing VM mode |
| `zone` | Zone of the target instance |
| `internal_ip` | Internal IP address for managed VM mode |
| `external_ip` | External IP address for managed VM mode |
| `service_account_email` | Service account email used for managed VM mode |
| `instana_endpoint` | Instana endpoint configured |
| `instana_agent_mode` | Instana agent mode configured |
| `ssh_command` | Command to SSH into the target instance |
| `agent_status_command` | Command to check agent status |
| `agent_logs_command` | Command to view installation logs |
| `agent_runtime_logs_command` | Command to view runtime logs |
| `existing_vm_install_script` | Rendered install script for existing VM mode |
| `existing_vm_install_command` | gcloud-based install command for existing VM mode |

## Architecture

### Components

```
┌─────────────────────────────────────────┐
│     Terraform Module                     │
│  terraform-gcp-instana-agent            │
├─────────────────────────────────────────┤
│                                          │
│  Variables → Locals → Resources         │
│                                          │
│  Resources Created:                      │
│  • google_compute_instance (1)          │
│  • google_service_account (0-1)         │
│                                          │
│  Outputs → Instance details, commands   │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│     GCP Infrastructure                   │
│                                          │
│  Compute Engine Instance                │
│  • Startup Script Execution             │
│    1. Download Instana setup script     │
│    2. Install prerequisites             │
│    3. Execute agent installation        │
│    4. Configure zone (optional)         │
│  • Instana Agent (running)              │
└─────────────────────────────────────────┘
         ↓
    Instana Backend
```

### Installation Flow

1. **Terraform Apply**: Creates GCP Compute Engine instance
2. **First Boot**: Startup script executes automatically
3. **Download**: Fetches Instana agent setup script
4. **Install**: Installs prerequisites and Instana agent
5. **Configure**: Sets up zone configuration (if specified)
6. **Verify**: Checks agent status and logs
7. **Report**: Agent begins reporting to Instana backend

## Security Considerations

### Credential Management

⚠️ **Important Security Notes:**

1. **Never commit credentials to version control**
   - Use `.gitignore` to exclude `*.tfvars`
   - Credentials are marked as `sensitive` in Terraform

2. **Credentials are stored in Terraform state**
   - Use encrypted remote backend (GCS, Terraform Cloud, S3)
   - Restrict state file access with IAM
   - Example backend configuration:

```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "instana-agent"
  }
}
```

3. **Use secure credential storage**
   - Store credentials in a password manager
   - Use environment variables for CI/CD
   - Rotate credentials regularly

### Public IP Access

🔒 **SECURITY WARNING**: By default, this module creates instances **with a public IP** (`enable_public_ip = true`) so the agent can reach `setup.instana.io` and the Instana backend during installation. Set `enable_public_ip = false` only if your VPC has Cloud NAT configured for outbound internet access.

#### Production Best Practices

**✅ Recommended Configuration (Private IP):**
```hcl
module "instana_agent" {
  source = "./terraform-gcp-instana-agent"
  
  # ... other configuration ...
  
  # Secure configuration - no public IP
  enable_public_ip = false
  network          = "custom-vpc"
  subnetwork       = "private-subnet"
  
  # Use restrictive network tags
  tags = ["instana-agent", "private-monitoring"]
}
```

#### Network Connectivity Requirements

**When External IP is NOT Present :**

The VM requires two critical configurations for proper operation:

1. **IAP Tunneling for SSH Access** (Required for Management)
2. **Outbound Internet Connectivity** (Required for Agent Installation & Communication)

##### 1. IAP Tunneling (Required for SSH Access)

Identity-Aware Proxy (IAP) enables secure SSH access to VMs without external IPs:

```hcl
module "instana_agent" {
  source = "./terraform-gcp-instana-agent"
  
  # ... other configuration ...
  
  # No public IP needed
  enable_public_ip = false
  
  # For existing VM mode
  use_iap_tunnel = true
}
```

**Connect via IAP:**
```bash
# SSH using IAP tunnel (no public IP required)
gcloud compute ssh INSTANCE_NAME \
  --zone=ZONE \
  --tunnel-through-iap
```

**Required IAM Permissions for IAP:**

The user or service account executing the SSH command needs:
- `roles/iap.tunnelResourceAccessor` - Allows IAP tunnel access


**IAP Benefits:**
- ✅ No public IP required
- ✅ Centralized access control via IAM
- ✅ Audit logging of all connections
- ✅ Context-aware access policies
- ✅ No VPN infrastructure needed

##### 2. Outbound Internet Connectivity

The VM must be able to establish outbound HTTPS (TCP port 443) connections to download and install the Instana agent and to communicate with external services.

For Google Cloud VMs without an external IP address, this is typically provided using Cloud NAT. Alternatively, customers may use another supported egress solution, such as an organizational HTTP/HTTPS proxy or centralized Internet gateway.

Note: If outbound Internet connectivity is not available, the agent installation will fail when attempting to download the required installation packages.

#### When External IP Is Present 

If you enable public IP, the VM can directly access the internet:

```hcl
module "instana_agent" {
  source = "./terraform-gcp-instana-agent"
  
  # ... other configuration ...
  
  # Public IP enabled - direct internet access
  enable_public_ip = true
}
```

**⚠️ Security Considerations:**
- VM is exposed to the internet
- Requires proper firewall rules
- Higher security risk
- Not recommended for production
- Consider using Cloud Armor for DDoS protection

### Network Security

- Ensure outbound HTTPS (443) is allowed
- Use firewall rules to restrict access
- Consider using Cloud NAT for instances without public IPs
- Use custom VPC with proper network segmentation in production
- Implement network policies and security groups
- Enable VPC Flow Logs for traffic analysis

### Service Account

- Use dedicated service account in production (`create_service_account = true`)
- Follow principle of least privilege
- Avoid using default compute service account
- Regularly audit service account permissions

## GCP Monitoring Best Practices

### 1. Single Project Per Agent
- Deploy one Instana agent per GCP project
- Folder-level permissions do not enable cross-project discovery
- Each agent requires its own host and service account

### 2. Service Account Security
- Use dedicated service account for monitoring
- Grant minimum required permissions only
- Rotate service account keys regularly
- Never commit key files to version control
- Store key files securely (encrypted storage, secrets manager)

### 3. Resource Filtering
Use the `include_tags` and `exclude_tags` fields in your `custom-config.yaml` to control what gets monitored:

```yaml
com.instana.plugin.gcp:
  credentials_path: ''    # Auto-updated by Terraform
  poll_rate: 60
  include_tags: 'environment:production,monitored:true'
  exclude_tags: 'environment:development,temporary:true'
```

### 4. Memory Sizing
Adjust agent memory based on environment size:

```hcl
# Small environment (< 50 resources)
agent_max_memory = 544  # Default

# Medium environment (50-200 resources)
agent_max_memory = 1024

# Large environment (> 200 resources)
agent_max_memory = 2048
```

### 5. Polling Rate Optimization
Set `poll_rate` in your `custom-config.yaml`:
- Default 60 seconds balances freshness and API costs
- Increase for less critical environments: `poll_rate: 120`
- Decrease for critical environments: `poll_rate: 30`
- Monitor GCP API quotas and costs


## Troubleshooting


### GCP Resources Not Appearing in Instana

**Symptoms:** Agent running but GCP resources not discovered

**Diagnosis:**
```bash
# Check GCP monitoring configuration
terraform output verify_gcp_monitoring_command | bash

# Verify credentials file
gcloud compute ssh INSTANCE_NAME --zone=ZONE \
  --command='sudo ls -la /opt/instana/agent/etc/instana/gcp-credentials.json'

# Check agent logs for GCP plugin
gcloud compute ssh INSTANCE_NAME --zone=ZONE \
  --command='sudo grep -i gcp /opt/instana/agent/data/log/agent.log'
```

**Common Solutions:**
- Verify service account has required permissions
- Check that service account key file project matches monitored project
- Ensure GCP APIs are enabled (Monitoring, Cloud SQL, etc.)
- Verify credentials file was deployed correctly
- Check for API quota limits in GCP Console

### Service Account Permission Issues

**Symptoms:** Agent can't access GCP resources

**Diagnosis:**
```bash
# Verify service account permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:YOUR_SA_EMAIL"
```

**Common Solutions:**
- Grant `roles/monitoring.viewer` role
- Verify all required permissions are present
- Check service account is in the correct project
- Ensure service account key is not expired

### Agent Installation Fails

**Symptoms:** VM created but agent not running

**Diagnosis:**
```bash
# View installation logs
terraform output agent_logs_command | bash

# Or SSH and check
gcloud compute ssh INSTANCE_NAME --zone=ZONE
sudo cat /var/log/instana-agent-install.log
```

**Common Solutions:**
- Verify Instana credentials are correct
- Check network connectivity to `setup.instana.io`
- Ensure outbound HTTPS (443) is allowed
- Verify Instana endpoint is correct

### Agent Not Reporting to Instana

**Symptoms:** Agent installed but not visible in Instana dashboard

**Diagnosis:**
```bash
# Check agent status
terraform output agent_status_command | bash

# View agent logs
terraform output agent_runtime_logs_command | bash
```

**Common Solutions:**
- Verify endpoint configuration
- Check firewall rules for outbound traffic
- Review agent logs for errors
- Verify credentials are correct
- Check Instana backend is accessible

### Permission Denied Errors

**Symptoms:** Terraform fails to create resources

**Diagnosis:** Review Terraform error messages

**Common Solutions:**
- Verify service account has required IAM roles
- Check API enablement in GCP project
- Ensure project ID is correct
- Verify you have permission to create resources

### Network Connectivity Issues

**Symptoms:** Agent can't reach Instana backend

**Diagnosis:**
```bash
# SSH to instance and test connectivity
gcloud compute ssh INSTANCE_NAME --zone=ZONE
curl -I https://setup.instana.io/agent
curl -I https://your-instana-endpoint:443
```

**Common Solutions:**
- Check firewall rules allow outbound HTTPS
- Verify VPC has internet gateway or Cloud NAT
- Check DNS resolution
- Verify endpoint URL is correct

## Verification

### Check Agent Status

```bash
# Using Terraform outputs
terraform output agent_status_command | bash

# Or SSH manually
gcloud compute ssh INSTANCE_NAME --zone=ZONE
sudo systemctl status instana-agent
```

### View Logs

```bash
# Installation logs
terraform output agent_logs_command | bash

# Runtime logs
terraform output agent_runtime_logs_command | bash
```

### Verify in Instana Dashboard

1. Log in to your Instana dashboard
2. Navigate to **Infrastructure** → **Hosts**
3. Search for your instance name
4. Verify metrics are being reported
5. Check the configured zone (if applicable)

## Maintenance

### Updating the Agent

The agent will auto-update by default. To manually update:

```bash
gcloud compute ssh INSTANCE_NAME --zone=ZONE
sudo systemctl restart instana-agent
```

### Updating the Instance

```bash
# Modify variables in terraform.tfvars
# Apply changes
terraform apply
```

### Destroying Resources

```bash
terraform destroy
```

## Best Practices

1. **Use Remote State**: Always use encrypted remote backend for state storage
2. **Dedicated Service Account**: Set `create_service_account = true` in production
3. **Custom VPC**: Use custom VPC with proper network segmentation
4. **Labels**: Use meaningful labels for cost tracking and organization
5. **Zone Configuration**: Use zone names for logical grouping in Instana
6. **Regular Updates**: Keep OS and agent updated
7. **Monitoring**: Set up alerts in Instana for agent health
8. **Documentation**: Document your specific configuration and customizations

## Module Development

### File Structure

```
terraform-gcp-instana-agent/
├── main.tf                    # Primary resources
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── locals.tf                  # Local values
├── data.tf                    # Data sources
├── versions.tf                # Provider constraints
├── startup-script.sh          # Agent installation script
├── terraform.tfvars.example   # Example variables
├── README.md                  # This file
├── .gitignore                 # Git ignore patterns
└── examples/
    ├── basic/                 # Basic example
    └── advanced/              # Advanced example
```

### Testing

```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Plan deployment
terraform plan

# Apply in test environment
terraform apply

# Verify agent installation
terraform output agent_status_command | bash

# Cleanup
terraform destroy
```

## Support and Contributing

### Getting Help

- Check the [examples](examples/) directory
- Review [troubleshooting](#troubleshooting) section
- Check [Instana documentation](https://www.ibm.com/docs/en/instana-observability/current)
- Review [GCP Compute Engine documentation](https://cloud.google.com/compute/docs)

### Reporting Issues

When reporting issues, please include:
- Terraform version
- Google Provider version
- Error messages
- Relevant logs from `/var/log/instana-agent-install.log`
- Your configuration (sanitized)

## License

This module is provided as-is for use with Instana monitoring on GCP.

## References

- [Instana Documentation](https://www.ibm.com/docs/en/instana-observability/current)
- [GCP Compute Engine](https://cloud.google.com/compute/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)

---