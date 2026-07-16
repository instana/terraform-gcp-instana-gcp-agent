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

- ✅ Larger machine type (`e2-standard-2`)
- ✅ SSD persistent disk (50 GB, `pd-ssd`)
- ✅ Dedicated service account for the VM
- ✅ GCP service account key for remote monitoring
- ✅ GCP poll rate and tag-based resource filtering
- ✅ Increased agent memory (1024 MB)
- ✅ Custom labels for organization and cost tracking
- ✅ Network tags for firewall rules
- ✅ Full set of GCP monitoring outputs

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
  - Automatic discovery and monitoring of GCP resources in the project

## GCP Resources Monitored

The Instana GCP plugin automatically discovers and monitors:

- Google Compute Engine instances
- Google Cloud SQL databases
- Google Kubernetes Engine (GKE) clusters
- Google Cloud Storage buckets
- Google Cloud Pub/Sub topics and subscriptions
- Google Cloud Datastore

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

### Instana Agent Modes

- `APM` — Application Performance Monitoring
- `INFRASTRUCTURE` — Infrastructure monitoring only
- `dynamic` — Dynamic mode (recommended default)
- `AWS` — AWS-specific monitoring
- `KUBERNETES` — Kubernetes monitoring

## Estimated Cost

Approximately **$64/month** (us-central1):

| Resource | Cost |
|----------|------|
| `e2-standard-2` instance | ~$48.54/month |
| 50 GB SSD disk | ~$8.50/month |
| External IP | ~$7.30/month |

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

## Network Configuration

### Using Default Network

```hcl
network    = "default"
subnetwork = null
```

### Using Custom VPC

```hcl
network    = "my-custom-vpc"
subnetwork = "my-custom-subnet-us-central1"
```

Ensure your VPC has:
- Internet gateway or Cloud NAT for outbound access
- Firewall rules allowing outbound HTTPS (443) to:
  - `setup.instana.io`
  - Your Instana backend endpoint
  - `monitoring.googleapis.com`
  - `cloudresourcemanager.googleapis.com`

## Single Project Monitoring

The Instana GCP agent monitors **one GCP project at a time**. To monitor multiple projects:

1. Deploy one dedicated agent per project
2. Each agent needs its own host VM
3. Each agent requires service account credentials for its specific project

## Cleanup

```bash
terraform destroy
```

This removes:
- The Compute Engine instance
- The dedicated service account
- All associated resources

## Troubleshooting

### Agent Not Installing

```bash
terraform output agent_logs_command | bash
# or
gcloud compute ssh instana-agent-prod-01 --zone=us-central1-a \
  --command='sudo cat /var/log/instana-agent-install.log'
```

### GCP Resources Not Appearing

Check the GCP monitoring configuration:

```bash
terraform output verify_gcp_monitoring_command | bash
```

Verify service account permissions:

```bash
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:instana-gcp-monitoring@YOUR_PROJECT_ID.iam.gserviceaccount.com"
```

### Service Account Issues

If using a custom VPC, ensure the VM's service account has:
- `compute.networkUser` role on the VPC
- Access to required GCP APIs

## Best Practices

1. **Dedicated Monitoring Service Account** — Use a least-privilege service account for GCP monitoring
2. **Dedicated VM Service Account** — Set `create_service_account = true` for the VM
3. **SSD Disks** — Use `pd-ssd` for better agent performance
4. **Tag Filtering** — Use `include_tags` in `custom-config.yaml` to limit monitoring scope in large projects
5. **Memory** — Set `agent_max_memory = 1024` or higher for large GCP environments
6. **Custom VPC** — Use custom VPC with proper network segmentation in production

## Next Steps

- Review the [basic example](../basic/) for the minimal configuration
- Review the [main module documentation](../../README.md)
- Set up alerting and custom dashboards in Instana
