# GitOps Deployment Guide with Flux

This guide documents the complete process of deploying applications to your Kubernetes homelab cluster using GitOps principles with Flux.

## Overview

GitOps is a deployment methodology where the desired state of your infrastructure and applications is stored in Git repositories. Flux continuously monitors these repositories and automatically applies changes to your Kubernetes cluster.

## Prerequisites

- Kubernetes cluster running (k3s homelab cluster)
- Flux v2 installed on the cluster
- Git repository for storing configuration (this repo)
- SSH access to the cluster nodes

## Repository Structure

```
homelab/
├── clusters/
│   └── homelab/
│       └── flux-system/
│           ├── gotk-components.yaml  # Flux components
│           ├── gotk-sync.yaml        # Main sync configuration
│           └── kustomization.yaml    # Flux system kustomization
├── apps/
│   └── [application-name]/
│       ├── kustomization.yaml        # App kustomization
│       ├── deployment.yaml           # K8s deployment
│       ├── service.yaml              # K8s service
│       └── configmap.yaml           # K8s configmap (optional)
└── infrastructure/
    └── [infrastructure-components]/  # Infrastructure as code
```

## Deployment Methods

### Method 1: Manual SOPS Deployment (Recommended for Testing)

For immediate deployment with local Age key decryption:

```bash
# 1. Apply namespace first
ssh root@<control-plane-ip> 'kubectl apply -f -' < apps/wallabag/namespace.yaml

# 2. Decrypt and apply secrets
sops -d apps/wallabag/secret.yaml | ssh root@<control-plane-ip> 'kubectl apply -f -'

# 3. Apply other resources
ssh root@<control-plane-ip> 'kubectl apply -f -' < apps/wallabag/configmap.yaml
```

**Benefits:**
- Age key stays on local machine (secure)
- Immediate deployment without GitOps setup
- Good for testing and development

**Process:**
1. Namespace must be applied first
2. Decrypt secrets locally using `sops -d`
3. Pipe decrypted content to remote kubectl via SSH

**Template command for any encrypted secret:**
```bash
sops -d <path-to-secret-file> | ssh root@<control-plane-ip> 'kubectl apply -f -'
```

### Method 2: GitHub Actions + SOPS + Flux (Recommended GitOps)

**Architecture**: No secrets stored on cluster, GitHub handles secret security

```
GitHub Push → GitHub Actions → Decrypt SOPS → kubectl apply secrets
                ↓
           Flux GitOps → Handle all other resources (deployments, services)
```

**Setup Process:**
1. Store Age private key in GitHub repository secrets
2. Create GitHub Actions workflow for secret deployment
3. Flux continues handling non-secret resources via GitOps

**Benefits:**
- ✅ No secrets stored on cluster nodes
- ✅ GitHub provides secure secret storage
- ✅ Maintains GitOps principles for applications
- ✅ Audit trail via GitHub Actions logs
- ✅ Same security model as manual SOPS deployment

**GitHub Actions Workflow** (to be created):
```yaml
name: Deploy Secrets
on: [push]
jobs:
  deploy-secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup SOPS & Age
        # Install SOPS and configure Age key from secrets
      - name: Deploy secrets
        # sops -d apps/*/secret.yaml | kubectl apply
```

### Method 3: GitOps with Flux (Traditional - Requires Secrets on Cluster)

## Step-by-Step Deployment Process

### Step 1: Verify Cluster Access

```bash
# SSH into cluster control plane (use root, alex user has no password)
ssh root@homelab-control-plane-6

# Verify cluster is running
kubectl get nodes

# Check if Flux is installed
kubectl get ns flux-system
flux version
```

### Critical Post-Deployment Steps

#### Fix K3s Worker Token Issue
After Terraform deployment, worker nodes will fail to join due to token mismatch:

```bash
# 1. Get the actual server token from control plane
SERVER_TOKEN=$(ssh root@homelab-control-plane-6 'sudo cat /var/lib/rancher/k3s/server/node-token')

# 2. Fix worker nodes with correct token
ssh root@homelab-worker-1-5 "sudo systemctl stop k3s-agent && curl -sfL https://get.k3s.io | K3S_URL=https://10.0.1.10:6443 K3S_TOKEN='$SERVER_TOKEN' INSTALL_K3S_EXEC='agent --node-ip=10.0.1.20' sh -"

ssh root@homelab-worker-2-5 "sudo systemctl stop k3s-agent && curl -sfL https://get.k3s.io | K3S_URL=https://10.0.1.10:6443 K3S_TOKEN='$SERVER_TOKEN' INSTALL_K3S_EXEC='agent --node-ip=10.0.1.21' sh -"

# 3. Verify all nodes joined
kubectl get nodes -o wide
```

#### Configure SSH Access (Optional)
The 'alex' user is created without password. To enable direct access:

```bash
# Option 1: Add your SSH key to alex user
for host in homelab-control-plane-6 homelab-worker-1-5 homelab-worker-2-5; do
  ssh root@$host "sudo -u alex mkdir -p /home/alex/.ssh && sudo -u alex cat >> /home/alex/.ssh/authorized_keys" < ~/.ssh/id_rsa.pub
done

# Option 2: Set password for alex user
for host in homelab-control-plane-6 homelab-worker-1-5 homelab-worker-2-5; do
  ssh root@$host "sudo passwd alex"
done
```

### Step 2: Prepare Application Manifests

Create your application directory structure:

```bash
mkdir -p apps/[app-name]
```

Required files:
- `kustomization.yaml` - Defines which resources to include
- `deployment.yaml` - Your application deployment
- `service.yaml` - Service to expose your application
- `configmap.yaml` - Configuration data (optional)

### Step 3: Create Flux GitOps Configuration

Create Flux resources to monitor and sync your application:

#### GitRepository Resource
Defines the Git repository Flux should monitor:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: [app-name]
  namespace: flux-system
spec:
  interval: 5m0s
  ref:
    branch: main
  url: https://github.com/[username]/[repo].git
```

#### Kustomization Resource
Defines how to apply the manifests:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: [app-name]
  namespace: flux-system
spec:
  interval: 5m0s
  path: "./apps/[app-name]"
  prune: true
  sourceRef:
    kind: GitRepository
    name: [app-name]
  targetNamespace: default
```

### Step 4: Apply Flux Configuration

```bash
# Apply the GitRepository
kubectl apply -f [app-name]-source.yaml

# Apply the Kustomization
kubectl apply -f [app-name]-kustomization.yaml
```

### Step 5: Verify Deployment

```bash
# Check Flux resources
kubectl get gitrepository -n flux-system
kubectl get kustomization -n flux-system

# Check application deployment
kubectl get pods -n [target-namespace]
kubectl get svc -n [target-namespace]

# Check Flux logs if needed
kubectl logs -n flux-system deployment/source-controller
kubectl logs -n flux-system deployment/kustomize-controller
```

### Step 6: Access Your Application

For external access, you have several options:

#### Option A: NodePort Service
```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```
Access via: `http://[cluster-ip]:30080`

#### Option B: Port Forward (for testing)
```bash
kubectl port-forward svc/[service-name] 8080:80 --address=0.0.0.0
```

## Troubleshooting

### Common Issues

1. **GitRepository not syncing**
   - Check network connectivity to GitHub
   - Verify repository URL and branch
   - Check authentication if repo is private

2. **Kustomization failing**
   - Verify path in Kustomization spec
   - Check YAML syntax in manifests
   - Ensure all referenced resources exist

3. **Application not starting**
   - Check pod logs: `kubectl logs [pod-name]`
   - Verify resource requests/limits
   - Check service selectors match pod labels

### Useful Commands

```bash
# Force Flux to sync immediately
flux reconcile source git [source-name]
flux reconcile kustomization [kustomization-name]

# Check Flux status
flux get sources git
flux get kustomizations

# Describe resources for detailed info
kubectl describe gitrepository [name] -n flux-system
kubectl describe kustomization [name] -n flux-system
```

## Best Practices

1. **Use semantic versioning** for application releases
2. **Separate environments** (dev, staging, prod) into different directories
3. **Use Kustomize overlays** for environment-specific configurations
4. **Monitor Flux resources** with alerting
5. **Test manifests locally** before pushing to Git
6. **Use resource limits** and requests for all applications
7. **Implement health checks** with readiness and liveness probes

## Next Steps

- Set up automatic image updates with Flux Image Automation
- Implement multi-environment deployments
- Add monitoring and alerting for GitOps operations
- Configure RBAC for different applications
- Set up disaster recovery procedures

---

*This guide documents the GitOps deployment process for the homelab Kubernetes cluster using Flux v2.*