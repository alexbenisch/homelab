# Homelab Infrastructure

A complete Infrastructure-as-Code solution for deploying a personal Kubernetes homelab on Hetzner Cloud with Tailscale mesh networking.

## 🎯 Purpose

This repository provides automated deployment of a production-ready k3s Kubernetes cluster with:
- Secure mesh networking via Tailscale
- Personal development environment setup
- GitOps-ready infrastructure
- Cost-effective cloud hosting on Hetzner

## 🏗️ Architecture

- **Infrastructure**: Hetzner Cloud VPS instances
- **Kubernetes**: k3s lightweight distribution
- **Networking**: Tailscale mesh + Hetzner private network
- **Configuration**: Terraform Infrastructure-as-Code
- **Environment**: Automated dotfiles and tool setup

## 📁 Repository Structure

```
homelab/
├── terraform/              # Main k3s cluster infrastructure
│   ├── main.tf             # Core infrastructure resources
│   ├── variables.tf        # Configuration variables
│   ├── outputs.tf          # Infrastructure outputs
│   └── lab.tfvars.example  # Configuration template
├── tailnet/                # Tailscale testing environment
│   ├── main.tf             # Test node resources  
│   ├── node-template.yaml  # Cloud-init for test nodes
│   └── tailnet.tfvars.example
├── templates/              # Cloud-init templates
│   ├── control-plane.yaml  # k3s control plane setup
│   └── worker.yaml         # k3s worker node setup
├── scripts/                # Helper scripts
│   ├── check_tailscale.sh  # Connectivity verification
│   └── create-tfvars.sh    # Generate tfvars from environment
└── docs/                   # Documentation
    └── private/            # Private notes and setup guides
```

## 🚀 Quick Start

### Prerequisites

1. **Hetzner Cloud Account**
   - API token with read/write permissions
   - SSH key uploaded as "alex@seven" in "kubernetes" project

2. **Tailscale Account**
   - Auth key for device registration

3. **Environment Variables** (in ~/.zshenv)
   - `HETZNER_TOKEN` - Your Hetzner Cloud API token
   - `TAILSCALE_AUTH_KEY` - Your Tailscale authentication key

4. **Local Tools**
   - Terraform >= 1.5
   - Git

### Deployment

1. **Clone and configure:**
```bash
git clone https://github.com/alexbenisch/homelab.git
cd homelab/
# Create tfvars files from environment variables
./scripts/create-tfvars.sh
```

2. **Deploy infrastructure:**
```bash
cd terraform/
terraform init
terraform plan -var-file="lab.tfvars"
terraform apply -var-file="lab.tfvars"
```

3. **Access your cluster:**
```bash
# SSH to control plane
ssh alex@<control-plane-ip>

# Get kubeconfig
terraform output kubeconfig_command
```

## ✨ Features

### 🔐 Security
- Private network isolation (10.0.0.0/16)
- SSH key authentication only
- Tailscale mesh encryption
- Secure token generation

### 🛠️ Development Experience
- Personal dotfiles automatically configured
- Zsh shell with custom prompt and aliases
- Pre-installed tools: kubectl, flux, k9s, tmux
- Consistent environment across all nodes

### 📊 Monitoring & Observability
- Automated Tailscale connectivity verification
- Cloud-init logging for troubleshooting
- Comprehensive terraform outputs

### 💰 Cost Optimization
- Lightweight k3s instead of full Kubernetes
- Efficient Hetzner Cloud pricing
- Minimal resource footprint
- Easy scaling and cleanup

## 🧪 Testing

Before deploying the full cluster, test Tailscale connectivity:

```bash
# Create tailnet variables (or use ./scripts/create-tfvars.sh tailnet)
./scripts/create-tfvars.sh tailnet
cd tailnet/
terraform init
terraform apply -var-file="tailnet.tfvars"
```

## 📖 Documentation

Complete documentation is maintained in the private `docs/private/` directory (gitignored) including:
- Infrastructure setup and deployment guides  
- Dotfiles integration details
- SSH configuration and access setup
- Credential management workflows

## 🔧 Configuration

### Default Settings
- **Location**: Nuremberg (nbg1)
- **Instance Type**: cx22 (2 vCPU, 4GB RAM)
- **Worker Nodes**: 2
- **Network**: 10.0.1.0/24 private subnet
- **OS**: Ubuntu 22.04 LTS

### Customization
All settings configurable via terraform variables:
- Instance sizes and counts
- Network configuration
- Cluster naming
- Location preferences

## 🤝 Contributing

This is a personal homelab setup, but feel free to fork and adapt for your own needs. Issues and suggestions welcome!

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- [k3s](https://k3s.io/) - Lightweight Kubernetes
- [Tailscale](https://tailscale.com/) - Zero-config VPN
- [Hetzner Cloud](https://www.hetzner.com/cloud) - Affordable cloud hosting
- [Terraform](https://terraform.io/) - Infrastructure as Code