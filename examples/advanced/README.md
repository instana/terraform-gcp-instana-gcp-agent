# Advanced Example - Instana Agent for GCP Remote Monitoring

This example demonstrates a **production-ready** configuration for deploying an Instana monitoring agent on a managed GCP Compute Engine instance with full GCP remote monitoring enabled.

## What This Example Includes

- Custom machine type and SSD disk for production workloads
- Dedicated service account for the VM
- Instana zone for logical grouping in the dashboard
- GCP monitoring plugin with optional resource-label filtering
- Custom agent memory configuration for large environments
- Custom labels and network tags
- All available GCP monitoring configuration options

## Features Demonstrated

- Larger machine type (`e2-standard-2`)
- SSD persistent disk (50 GB, `pd-ssd`)
- Dedicated service account for the VM
- GCP service account key for remote monitoring
- GCP poll rate and tag-based resource filtering
- Increased agent memory (1024 MB)
- Custom labels for organization and cost tracking
- Network tags for firewall rules
- Full set of GCP monitoring outputs

## Prerequisites

### 1. GCP Project Setup

- GCP project with billing enabled
- Required APIs enabled:
  - Compute Engine API
  - Cloud Monitoring API
  - IAM API
  - Cloud SQL Admin API (if monitoring Cloud SQL)
  - Kubernetes Engine API (if monitoring GKE)
  - Cloud Storage API (if monitoring Storage)
  - Cloud Pub/Sub API (if monitoring Pub/Sub)

### 2. Service Account for GCP Monitoring

Create a dedicated service account with monitoring permissions:

```bash
# Create the monitoring service account
gcloud iam service-accounts create instana-gcp-monitoring \
  --display-name="Instana GCP Monitoring" \
  --project=YOUR_PROJECT_ID

# Grant the required monitoring role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:instana-gcp-monitoring@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/monitoring.viewer"

# Download the JSON key file
gcloud iam service-accounts keys create ~/instana-gcp-key.json \
  --iam-account=instana-gcp-monitoring@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

**Required IAM Permissions:**
- `monitoring.timeSeries.list` — Read monitoring metrics
- `pubsub.subscriptions.list` — List Pub/Sub subscriptions
- `pubsub.topics.list` — List Pub/Sub topics
- `resourcemanager.projects.get` — Get project information
- `cloudsql.instances.list` — List Cloud SQL instances
- `storage.buckets.list` — List Cloud Storage buckets

### 3. Instana Credentials

- Valid Instana agent key
- Valid Instana download key
- Instana backend endpoint

### 4. Tools

- Terraform >= 1.3.0 installed
- gcloud CLI configured

## Usage

### 1. Copy the Example Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit `terraform.tfvars`

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"

instance_name     = "instana-agent-prod-01"
machine_type      = "e2-standard-2"
boot_disk_size_gb = 50
boot_disk_type    = "pd-ssd"

instana_endpoint_host = "your-instana-endpoint.instana.rocks"
instana_agent_key     = "your-agent-key"
instana_download_key  = "your-download-key"
instana_agent_mode    = "dynamic"

# GCP Monitoring
gcp_service_account_key_file = "/path/to/instana-gcp-key.json"

# Custom Configuration — set poll_rate, include_tags, exclude_tags here
# cp custom-config.yaml.example custom-config.yaml
# custom_configuration_file = "/absolute/path/to/examples/advanced/custom-config.yaml"

agent_max_memory = 1024

create_service_account = true

labels = {
  environment = "production"
  team        = "platform"
  managed_by  = "terraform"
}
```

> **Security Note:** Never commit `terraform.tfvars` or the service account key file to version control.

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

```bash
# Check agent status
terraform output agent_status_command | bash

# View installation logs
terraform output agent_logs_command | bash

# View agent runtime logs
terraform output agent_runtime_logs_command | bash

# Verify GCP monitoring configuration
terraform output verify_gcp_monitoring_command | bash
```

## What Gets Created

- 1 × GCP Compute Engine instance (`e2-standard-2`)
- 1 × 50 GB SSD persistent disk (`pd-ssd`)
- 1 × Dedicated service account for the VM
- 1 × External IP address (ephemeral)
- Instana agent installed and configured with:
  - GCP remote monitoring plugin
  - GCP service account credentials deployed to `/opt/instana/agent/etc/instana/gcp-credentials.json`
  - GCP resource monitoring available once explicitly enabled via custom-config.yaml


## Configuration Options

### Machine Types

| Type | vCPUs | RAM | Use Case |
|------|-------|-----|----------|
| `e2-medium` | 2 | 4 GB | Development / basic |
| `e2-standard-2` | 2 | 8 GB | Production (recommended) |
| `e2-standard-4` | 4 | 16 GB | High load / many resources |

### Disk Types

| Type | Description |
|------|-------------|
| `pd-standard` | Standard persistent disk (lowest cost) |
| `pd-balanced` | Balanced performance/cost |
| `pd-ssd` | SSD persistent disk (best performance) |

### GCP Poll Rate

Controls how often the GCP Monitoring API is polled. Set `poll_rate` in your `custom-config.yaml`:

```yaml
com.instana.plugin.gcp:
  credentials_path: ''
  poll_rate: 60    # 30 = near real-time; 60 = recommended; 300 = low API usage
  include_tags: ''
  exclude_tags: ''
```

### Tag Filtering

Set `include_tags` and `exclude_tags` in your `custom-config.yaml`:

```yaml
com.instana.plugin.gcp:
  credentials_path: ''
  poll_rate: 60
  include_tags: 'environment:production,team:platform'
  exclude_tags: 'environment:development,temporary:true'
```

## Outputs

After deployment:

```bash
# View all outputs
terraform output

# Key outputs
terraform output instance_id
terraform output internal_ip
terraform output external_ip
terraform output service_account_email
terraform output instana_endpoint
terraform output gcp_monitoring_configuration
terraform output verify_gcp_monitoring_command
```

## Verification

### Check Agent Status

```bash
# Using Terraform output
terraform output agent_status_command | bash

# Or SSH manually
gcloud compute ssh instana-agent-prod-01 --zone=us-central1-a
sudo systemctl status instana-agent
```

### Verify GCP Monitoring Configuration

```bash
# Verify configuration.yaml contains GCP plugin config
terraform output verify_gcp_monitoring_command | bash

# Verify credentials file is in place
gcloud compute ssh instana-agent-prod-01 --zone=us-central1-a \
  --command='sudo ls -la /opt/instana/agent/etc/instana/gcp-credentials.json'
```

### Check in Instana Dashboard

1. Log in to your Instana dashboard
2. Navigate to **Infrastructure → Google Cloud Platform**
3. Filter by zone: `production-us-central`
4. Verify your GCP project appears
5. Check that resources (GCE, Cloud SQL, GKE, Storage, Pub/Sub) are being discovered

## Cleanup

```bash
terraform destroy
```

This removes:
- The Compute Engine instance
- The dedicated service account
- All associated resources
