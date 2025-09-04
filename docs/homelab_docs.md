# Homelab Infrastructure Documentation

## Overview

This repository contains Infrastructure as Code (IaC) for a personal homelab setup built on Hetzner Cloud with GitOps deployment patterns. The infrastructure provides a lightweight, secure, and scalable Kubernetes environment using k3s.

## Architecture

### Infrastructure Components

#### Cloud Provider: Hetzner Cloud
- **Platform**: Hetzner Cloud (configurable region)
- **Networking**: Private VPC (192.168.0.0/16)
- **Subnet**: 192.168.1.0/24 for cluster nodes
- **Access**: Tailscale VPN for secure connectivity

#### Kubernetes Cluster
- **Distribution**: k3s (lightweight Kubernetes)
- **Control Plane**: Single node (192.168.1.10)
- **Workers**: Configurable count (192.168.1.20+)
- **Version**: Latest stable k3s release
- **Components**: CoreDNS, Traefik, Local Path Provisioner, Metrics Server

#### GitOps Platform
- **Tool**: Flux v2
- **Repository**: GitHub
- **Branch**: main
- **Path**: clusters/homelab
- **Sync**: Automated deployment and reconciliation

### Security Model

#### Network Security
- **Private Network**: All inter-node communication via private network
- **VPN Access**: Tailscale mesh network for secure external access
- **No Public Access**: SSH and Kubernetes API not exposed publicly
- **Firewall**: Hetzner Cloud firewall rules

#### Access Control
- **SSH Keys**: Key-based authentication only
- **Tailscale Auth**: Device-based access control
- **Kubernetes RBAC**: Role-based access control
- **Secrets Management**: Encrypted secrets with SOPS/Age

## Repository Structure

```
homelab/
├── docs/                              # Documentation
│   └── homelab_docs.md               # This file
├── 
├── # Terraform Infrastructure
├── main.tf                           # Main Terraform configuration
├── variables.tf                      # Variable definitions
├── outputs.tf                        # Output definitions
├── lab.tfvars                        # Configuration values (example)
├── 
├── # Cloud-init Templates
├── templates/
│   ├── control-plane.yaml           # Control plane bootstrap
│   └── worker.yaml                   # Worker node bootstrap
├── 
├── # Helper Scripts
├── scripts/
│   ├── check_tailscale.sh           # Tailscale connectivity verification
│   ├── kubectl-with-sops.sh         # Kubectl with SOPS integration
│   ├── terraform-with-sops.sh       # Terraform with SOPS integration
│   └── update-secrets.sh            # Secret management helper
├── 
├── # GitOps Configuration
├── clusters/homelab/
│   ├── flux-system/                  # Core Flux components
│   │   ├── gotk-components.yaml     # Flux toolkit components
│   │   ├── gotk-sync.yaml           # Main sync configuration
│   │   └── kustomization.yaml       # Flux system kustomization
│   └── apps/                         # Application configurations
│       └── *-kustomization.yaml     # App-specific kustomizations
├── 
└── # Application Manifests
└── apps/
    ├── hello-world/                  # Example application
    ├── wallabag/                     # Personal bookmark manager
    └── */                            # Other applications
```

## Infrastructure Components

### Terraform Configuration

#### Providers
- **hcloud**: Hetzner Cloud provider (~> 1.52)
- **random**: Token generation (~> 3.4)
- **null**: Provisioner execution (~> 3.2)

#### Resources
- **hcloud_network**: Private VPC network
- **hcloud_network_subnet**: Cluster subnet
- **hcloud_server**: Control plane and worker nodes
- **random_password**: k3s cluster token
- **null_resource**: Tailscale connectivity checks

### Server Configuration

#### Control Plane Node
- **Type**: Configurable (default: cpx21)
- **Image**: Ubuntu 22.04 LTS
- **IP**: 192.168.1.10 (static)
- **Role**: k3s server with embedded etcd
- **Services**: API server, scheduler, controller-manager

#### Worker Nodes
- **Type**: Configurable (default: cpx11)
- **Image**: Ubuntu 22.04 LTS
- **IPs**: 192.168.1.20+ (sequential)
- **Role**: k3s agents
- **Join**: Automatic via cloud-init

### Cloud-init Bootstrap

#### Common Setup
- Package updates and installation
- Docker runtime installation
- Tailscale agent setup and authentication
- SSH hardening
- System monitoring setup

#### Control Plane Specific
- k3s server installation with cluster token
- Traefik configuration
- Flux CLI installation
- GitOps bootstrap preparation

#### Worker Specific
- k3s agent installation
- Control plane connection
- Automatic cluster joining

## GitOps Workflow

### Flux Configuration

#### Core Components
- **Source Controller**: Git repository monitoring
- **Kustomize Controller**: Manifest application
- **Helm Controller**: Helm chart deployment
- **Image Controller**: Container image automation

#### Repository Structure
- **clusters/**: Environment-specific configurations
- **apps/**: Application manifests
- **infrastructure/**: Shared infrastructure components

### Deployment Process

1. **Code Commit**: Push changes to Git repository
2. **Source Sync**: Flux detects repository changes
3. **Manifest Application**: Kustomize applies configurations
4. **Health Check**: Flux verifies deployment status
5. **Reconciliation**: Automatic drift correction

### Application Management

#### Application Structure
```yaml
# app-kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: app-name
  namespace: flux-system
spec:
  interval: 5m
  path: ./apps/app-name
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

#### Deployment Patterns
- **Kustomize**: Native Kubernetes manifests
- **Helm**: Chart-based deployments
- **ConfigMaps**: Environment-specific configuration
- **Secrets**: Encrypted with SOPS/Age

## Security Implementation

### Secrets Management

#### SOPS/Age Integration
- **Encryption**: Age-based encryption
- **Key Management**: Age key pairs
- **Git Integration**: Encrypted secrets in repository
- **Automatic Decryption**: Runtime secret decryption

#### Secret Structure
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  key: <encrypted-value>
```

### Access Control

#### Tailscale Integration
- **Device Authentication**: OAuth-based device approval
- **Network Segmentation**: Isolated homelab network
- **DNS Resolution**: Custom DNS for services
- **ACL Policies**: Granular access control

#### SSH Security
- **Key-based Authentication**: No password access
- **Port Configuration**: Non-standard SSH ports
- **Fail2ban**: Intrusion prevention
- **Regular Updates**: Automated security updates

## Monitoring & Observability

### System Monitoring
- **Node Exporter**: System metrics collection
- **Prometheus**: Metrics aggregation
- **Grafana**: Visualization and dashboards
- **AlertManager**: Alert routing and notification

### Application Monitoring
- **Service Metrics**: Application-specific metrics
- **Log Aggregation**: Centralized logging
- **Health Checks**: Liveness and readiness probes
- **Tracing**: Distributed request tracing

## Backup & Recovery

### Infrastructure Backup
- **Terraform State**: Remote state storage
- **Configuration**: Git-based version control
- **Snapshots**: Hetzner Cloud volume snapshots
- **Disaster Recovery**: Infrastructure recreation

### Data Backup
- **Persistent Volumes**: Regular backups
- **Database Dumps**: Application data export
- **Configuration Backup**: Secret and config export
- **Restoration**: Automated recovery procedures

## Operations Guide

### Daily Operations
- **Health Monitoring**: System and application status
- **Log Review**: Error and warning analysis
- **Security Updates**: Automated patching
- **Performance Monitoring**: Resource utilization

### Maintenance Tasks
- **Certificate Rotation**: TLS certificate renewal
- **Backup Verification**: Recovery testing
- **Security Scanning**: Vulnerability assessment
- **Capacity Planning**: Resource scaling

### Troubleshooting
- **Flux Status**: `flux get all`
- **Pod Logs**: `kubectl logs -f pod-name`
- **Node Status**: `kubectl get nodes -o wide`
- **Event Monitoring**: `kubectl get events --sort-by='.lastTimestamp'`

## Future Enhancements

### Planned Features
- **Multi-Environment**: Development and staging clusters
- **Image Automation**: Automatic image updates
- **Advanced Monitoring**: Service mesh observability
- **Security Scanning**: Container vulnerability scanning

### Integration Roadmap
- **CI/CD Pipelines**: GitHub Actions integration
- **External DNS**: Automatic DNS management
- **Certificate Management**: Let's Encrypt automation
- **Service Mesh**: Istio or Linkerd implementation

---

*Documentation maintained as part of the homelab infrastructure repository*
*Last updated: 2025-09-03*