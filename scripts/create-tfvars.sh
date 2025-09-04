#!/bin/bash

# Source environment variables from ~/.zshenv
source ~/.zshenv

# Create terraform variables file
create_terraform_tfvars() {
    local output_file="$1"
    
    cat > "$output_file" << EOF
# Hetzner Cloud configuration
hcloud_token = "$HETZNER_TOKEN"

# Tailscale configuration  
tailscale_auth_key = "$TAILSCALE_AUTH_KEY"

# Cluster configuration
cluster_name = "homelab"
location = "nbg1"

# Server sizing
server_type_control_plane = "cx22"
server_type_worker = "cx22"
worker_count = 2
EOF
    
    echo "Created $output_file with environment variables from ~/.zshenv"
}

# Create tailnet variables file
create_tailnet_tfvars() {
    local output_file="$1"
    
    cat > "$output_file" << EOF
# Hetzner Cloud configuration
hcloud_token = "$HETZNER_TOKEN"

# Tailscale configuration
tailscale_auth_key = "$TAILSCALE_AUTH_KEY"

# Test node configuration
node_count = 3
location = "nbg1"
server_type = "cx22"
EOF
    
    echo "Created $output_file with environment variables from ~/.zshenv"
}

# Main execution
case "$1" in
    terraform)
        create_terraform_tfvars "terraform/lab.tfvars"
        ;;
    tailnet)
        create_tailnet_tfvars "tailnet/tailnet.tfvars"
        ;;
    both|*)
        create_terraform_tfvars "terraform/lab.tfvars"
        create_tailnet_tfvars "tailnet/tailnet.tfvars"
        ;;
esac