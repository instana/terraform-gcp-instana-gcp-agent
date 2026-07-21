#!/bin/bash
#
# Instana Agent Installation Script for GCP Compute Engine
# This script is executed on first boot to install and configure the Instana agent
#
set -e
set -o pipefail

# ==============================================================================
# Configuration
# ==============================================================================

LOG_FILE="/var/log/instana-agent-install.log"
SETUP_SCRIPT="/tmp/setup_agent.sh"

# ==============================================================================
# Functions
# ==============================================================================

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# ==============================================================================
# Main Installation Process
# ==============================================================================

# Redirect all output to log file
exec > >(tee -a "$LOG_FILE")
exec 2>&1

log "========================================="
log "Instana Agent Installation Starting"
log "========================================="

# Read configuration from environment variables or GCP metadata server
log "Reading configuration..."

get_config_value() {
    local env_var_name="$1"
    local metadata_key="$2"
    local env_value="${!env_var_name:-}"

    if [ -n "$env_value" ]; then
        printf '%s' "$env_value"
        return 0
    fi

    curl -fs -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/instance/attributes/${metadata_key}" 2>/dev/null || true
}

INSTANA_AGENT_KEY=$(get_config_value "INSTANA_AGENT_KEY" "INSTANA_AGENT_KEY")
INSTANA_DOWNLOAD_KEY=$(get_config_value "INSTANA_DOWNLOAD_KEY" "INSTANA_DOWNLOAD_KEY")
INSTANA_ENDPOINT_HOST=$(get_config_value "INSTANA_ENDPOINT_HOST" "INSTANA_ENDPOINT_HOST")
INSTANA_ENDPOINT_PORT=$(get_config_value "INSTANA_ENDPOINT_PORT" "INSTANA_ENDPOINT_PORT")
INSTANA_AGENT_MODE=$(get_config_value "INSTANA_AGENT_MODE" "INSTANA_AGENT_MODE")
AGENT_MAX_MEM=$(get_config_value "AGENT_MAX_MEM" "AGENT_MAX_MEM")

# GCP Monitoring Configuration
GCP_KEY_BASE64=$(get_config_value "GCP_KEY_BASE64" "GCP_KEY_BASE64")
GCP_CREDENTIALS_PATH=$(get_config_value "GCP_CREDENTIALS_PATH" "GCP_CREDENTIALS_PATH")
GCP_PROJECT_ID=$(get_config_value "GCP_PROJECT_ID" "GCP_PROJECT_ID")

# Custom Configuration
CUSTOM_CONFIG_BASE64=$(get_config_value "CUSTOM_CONFIG_BASE64" "CUSTOM_CONFIG_BASE64")

log "Configuration loaded:"
log "  Endpoint: $INSTANA_ENDPOINT_HOST:$INSTANA_ENDPOINT_PORT"
log "  Agent Mode: $INSTANA_AGENT_MODE"
log "  Agent Max Memory: ${AGENT_MAX_MEM:-544M}"
if [ -n "$GCP_PROJECT_ID" ]; then
    log "  GCP Project: $GCP_PROJECT_ID"
fi

# Validate credentials
if [ -z "$INSTANA_AGENT_KEY" ] || [ -z "$INSTANA_DOWNLOAD_KEY" ]; then
    error_exit "Credentials are empty. Please check your Terraform configuration."
fi

log "✓ Credentials validated"

# Download Instana setup script
log "Downloading Instana agent setup script..."
if ! curl -o "$SETUP_SCRIPT" https://setup.instana.io/agent; then
    error_exit "Failed to download Instana setup script from https://setup.instana.io/agent"
fi

chmod 700 "$SETUP_SCRIPT"
log "✓ Setup script downloaded"

# Complete cleanup of any previous Instana installation
# (must run before apt-get update to avoid 401 from stale repo sources)
log "Performing complete cleanup of any previous Instana installation..."
systemctl stop instana-agent 2>/dev/null || true
apt-get remove --purge -y instana-agent-* 2>/dev/null || true
rm -rf /opt/instana
rm -rf /var/lib/instana
rm -f /etc/apt/sources.list.d/instana-*.list
rm -f /etc/apt/auth.conf.d/instana-*.conf
rm -f /usr/share/keyrings/instana-*.gpg
apt-get autoremove -y 2>/dev/null || true
apt-get clean
log "✓ Cleanup completed"

# Install prerequisites
log "Installing prerequisites..."
apt-get update -qq || error_exit "Failed to update package lists"
apt-get install -y -qq apt-transport-https ca-certificates || error_exit "Failed to install prerequisites"
log "✓ Prerequisites installed"


# Set agent memory limit if specified
if [ -n "$AGENT_MAX_MEM" ]; then
    log "Setting agent memory limit to $AGENT_MAX_MEM"
    export AGENT_MAX_MEM
fi

# Construct endpoint
INSTANA_ENDPOINT="${INSTANA_ENDPOINT_HOST}:${INSTANA_ENDPOINT_PORT}"
log "Installing Instana agent with endpoint: $INSTANA_ENDPOINT"

# Install Instana agent
log "Executing Instana agent installation..."
if ! "$SETUP_SCRIPT" \
    -a "$INSTANA_AGENT_KEY" \
    -d "$INSTANA_DOWNLOAD_KEY" \
    -t "$INSTANA_AGENT_MODE" \
    -e "$INSTANA_ENDPOINT" \
    -s \
    -y; then
    error_exit "Instana agent installation failed. Check the logs above for details."
fi

log "✓ Instana agent installed successfully"

# ==============================================================================
# Setup GCP Credentials (if provided)
# ==============================================================================

if [ -n "$GCP_KEY_BASE64" ] && [ -n "$GCP_CREDENTIALS_PATH" ]; then
    log "Setting up GCP service account credentials..."
    
    # Create directory for GCP credentials if it doesn't exist
    GCP_CREDS_DIR=$(dirname "$GCP_CREDENTIALS_PATH")
    mkdir -p "$GCP_CREDS_DIR"
    chmod 755 "$GCP_CREDS_DIR"
    
    # Decode and save the GCP service account key file
    echo "$GCP_KEY_BASE64" | base64 -d > "$GCP_CREDENTIALS_PATH"
    chmod 600 "$GCP_CREDENTIALS_PATH"
    log "✓ GCP credentials saved to $GCP_CREDENTIALS_PATH"
    
    log "  Project: $GCP_PROJECT_ID"
    log "  Credentials: $GCP_CREDENTIALS_PATH"
fi

# ==============================================================================
# Append Custom Configuration
# ==============================================================================

if [ -n "$CUSTOM_CONFIG_BASE64" ]; then
    CUSTOM_CONFIG_APPLIED=true
    log "Appending custom configuration to agent configuration.yaml..."
    
    CONFIG_FILE="/opt/instana/agent/etc/instana/configuration.yaml"
    
    # Backup the configuration file
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%s)"
    log "✓ Configuration backup created"
    
    # Decode and append custom configuration
    echo "" >> "$CONFIG_FILE"
    echo "# Custom Configuration (added by Terraform)" >> "$CONFIG_FILE"
    echo "$CUSTOM_CONFIG_BASE64" | base64 -d >> "$CONFIG_FILE"
    
    log "✓ Custom configuration appended successfully"
    
    # Update credentials_path in ALL uncommented GCP plugin sections if GCP credentials are provided
    if [ -n "$GCP_CREDENTIALS_PATH" ]; then
        log "Updating GCP credentials_path in all uncommented GCP plugin configurations..."
        
        # Use perl for in-place editing with proper section tracking
        # Pass the credentials path as an environment variable to avoid Perl variable interpolation issues
        CREDS_PATH="$GCP_CREDENTIALS_PATH" perl -i -pe '
            BEGIN { $creds = $ENV{CREDS_PATH}; }
            # Track if we are in a GCP plugin section
            if (/^com\.instana\.plugin\.gcp/) {
                $in_gcp = 1;
            }
            # Exit GCP section when we hit a non-indented, non-comment, non-gcp line
            elsif ($in_gcp && /^[^\s#]/ && !/^com\.instana\.plugin\.gcp/) {
                $in_gcp = 0;
            }
            # Update credentials_path if we are in a GCP section
            if ($in_gcp && /^\s+credentials_path:/) {
                s|^(\s*)credentials_path:.*|${1}credentials_path: '"'"'$creds'"'"'|;
            }
        ' "$CONFIG_FILE"
        
        log "✓ GCP credentials_path updated in all uncommented GCP plugin sections to: $GCP_CREDENTIALS_PATH"
    fi
    
    log "  Note: Agent will auto-detect configuration changes"
fi


# Verify agent is running
log "Verifying agent status..."
if systemctl is-active --quiet instana-agent; then
    log "✓ Instana agent is running"
    systemctl status instana-agent --no-pager | tee -a "$LOG_FILE"
else
    log "⚠ WARNING: Instana agent is not running"
    systemctl status instana-agent --no-pager | tee -a "$LOG_FILE"
    error_exit "Agent failed to start. Check systemctl status instana-agent for details."
fi

# Cleanup
log "Cleaning up temporary files..."
rm -f "$SETUP_SCRIPT"

# Clear sensitive variables from memory
unset INSTANA_AGENT_KEY
unset INSTANA_DOWNLOAD_KEY
unset GCP_KEY_BASE64
unset CUSTOM_CONFIG_BASE64
CUSTOM_CONFIG_APPLIED="${CUSTOM_CONFIG_APPLIED:-false}"

log "========================================="
log "Instana Agent Installation Complete"
log "========================================="
log "Agent Status: Running"
log "Endpoint: $INSTANA_ENDPOINT"
log "Mode: $INSTANA_AGENT_MODE"
[ "$CUSTOM_CONFIG_APPLIED" = "true" ] && log "Custom Configuration: Applied"
log "========================================="
log ""
log "To check agent status: sudo systemctl status instana-agent"
log "To view agent logs: sudo tail -f /opt/instana/agent/data/log/agent.log"
log "Installation log: $LOG_FILE"

exit 0
