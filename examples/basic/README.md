# Basic Example - Instana Agent for GCP Remote Monitoring

This example demonstrates the minimal configuration required to deploy an Instana monitoring agent for monitoring GCP resources remotely.

## What This Example Does

- Creates a single GCP Compute Engine instance to host the Instana agent
- Installs Instana agent automatically via startup script
- Configures GCP monitoring plugin with customer-provided service account credentials
- Enables monitoring of GCP resources when explicitly enabled via `custom-config.yaml`:
  - Google Compute Engine instances
  - Google Cloud SQL databases
  - Google Kubernetes Engine (GKE) clusters
  - Google Cloud Storage buckets
  - Google Cloud Pub/Sub topics and subscriptions
  - Google Cloud Datastore


## Prerequisites

### 1. GCP Project Setup
- GCP project with billing enabled
- Required APIs enabled:
  - Compute Engine API
  - Cloud Monitoring API
  - Cloud SQL Admin API (if monitoring Cloud SQL)
  - Kubernetes Engine API (if monitoring GKE)
  - Cloud Storage API (if monitoring Storage)
  - Cloud Pub/Sub API (if monitoring Pub/Sub)

### 2. Service Account for Monitoring
Create a dedicated service account with monitoring permissions:

```bash
# Create service account
gcloud iam service-accounts create instana-gcp-monitoring \
  --display-name="Instana GCP Monitoring" \
  --project=YOUR_PROJECT_ID

# Grant required permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:instana-gcp-monitoring@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/monitoring.viewer"

# Create and download JSON key
gcloud iam service-accounts keys create ~/instana-gcp-key.json \
  --iam-account=instana-gcp-monitoring@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

**Required IAM Permissions:**
- `monitoring.timeSeries.list` - Read monitoring metrics
- `pubsub.subscriptions.list` - List Pub/Sub subscriptions
- `pubsub.topics.list` - List Pub/Sub topics
- `resourcemanager.projects.get` - Get project information
- `cloudsql.instances.list` - List Cloud SQL instances
- `storage.buckets.list` - List Cloud Storage buckets

### 3. Instana Credentials
- Valid Instana agent key
- Valid Instana download key
- Instana backend endpoint

### 4. Tools
- Terraform >= 1.3.0 installed
- gcloud CLI configured (optional, for SSH access)

## Usage

### 1. Copy the Example Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit terraform.tfvars

```hcl
# GCP Configuration
project_id = "your-gcp-project-id"
zone       = "us-central1-a"

# Instance Configuration
instance_name = "instana-agent-basic"

# Instana Configuration
instana_endpoint_host = "your-instana-endpoint.instana.rocks"
instana_agent_key     = "your-agent-key"
instana_download_key  = "your-download-key"

# GCP Monitoring Configuration
gcp_service_account_key_file = "/path/to/instana-gcp-key.json"

# Custom Configuration — set poll_rate, include_tags, exclude_tags here
# cp custom-config.yaml.example custom-config.yaml
# custom_configuration_file = "/absolute/path/to/examples/basic/custom-config.yaml"
```

**Security Note:** Never commit the service account key file or terraform.tfvars to version control!

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy

```bash
terraform apply
```

### 6. Verify Installation

After deployment, check the agent status:

```bash
# Get the SSH command from outputs
terraform output ssh_command

# Or check agent status directly
terraform output agent_status_command | bash
```

## What Gets Created

- 1 x GCP Compute Engine instance (e2-medium) hosting the Instana agent
- 1 x 20GB persistent disk (pd-balanced)
- 1 x External IP address (ephemeral)
- Instana agent installed and configured with GCP monitoring plugin
- GCP service account credentials deployed to the agent
- GCP resource monitoring available once explicitly enabled via `custom-config.yaml`

## Outputs

After deployment, you'll get:

**Instance Outputs:**
- `instance_id` - Instance ID
- `instance_name` - Instance name
- `internal_ip` - Internal IP address
- `external_ip` - External IP address

**GCP Monitoring Outputs:**
- `gcp_monitoring_project_id` - Project being monitored
- `gcp_credentials_path` - Path to credentials on agent host
- `gcp_monitoring_configuration` - Monitoring config summary

**Operational Outputs:**
- `ssh_command` - Ready-to-use SSH command
- `agent_status_command` - Command to check agent status
- `agent_logs_command` - Command to view installation logs
- `verify_gcp_monitoring_command` - Command to verify GCP monitoring config

## Verification

### Check Agent Status

```bash
# Using Terraform output
terraform output agent_status_command | bash

# Or SSH manually
gcloud compute ssh instana-agent-basic --zone=us-central1-a
sudo systemctl status instana-agent
```

### View Installation Logs

```bash
terraform output agent_logs_command | bash
```

### Verify GCP Monitoring Configuration

```bash
# Check GCP monitoring configuration
terraform output verify_gcp_monitoring_command | bash

# Verify credentials file exists
gcloud compute ssh instana-agent-basic --zone=us-central1-a \
  --command='sudo ls -la /opt/instana/agent/etc/instana/gcp-credentials.json'
```

### Check in Instana Dashboard

1. Log in to your Instana dashboard
2. Navigate to Infrastructure → Google Cloud Platform
3. Verify your GCP project appears
4. Check that GCP resources are being discovered:
   - Compute Engine instances
   - Cloud SQL databases
   - GKE clusters
   - Cloud Storage buckets
   - Pub/Sub topics
5. Verify metrics are being collected

## Cleanup

To destroy all resources:

```bash
terraform destroy
```
