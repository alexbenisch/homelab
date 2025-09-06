# SOPS Usage Guide

This document explains how to use SOPS (Secrets OPerationS) with Age encryption in your homelab infrastructure.

## Overview

SOPS is now integrated into the homelab infrastructure to secure:
- Terraform variables (API tokens, keys)
- Kubernetes secrets (database passwords, application secrets)

## Files Structure

```
homelab/
├── .sops.yaml                    # SOPS configuration
├── secrets.tfvars               # Encrypted Terraform secrets
├── apps/wallabag/secret.yaml    # Encrypted Kubernetes secrets
└── scripts/
    ├── terraform-with-sops.sh   # Terraform wrapper with SOPS
    └── kubectl-with-sops.sh     # kubectl wrapper with SOPS
```

## Usage

### Editing Encrypted Secrets

**Terraform secrets:**
```bash
sops secrets.tfvars
```

**Kubernetes secrets:**
```bash
sops apps/wallabag/secret.yaml
```

### Running Terraform with Encrypted Secrets

Use the wrapper script instead of direct terraform commands:

```bash
# Initialize
./scripts/terraform-with-sops.sh init

# Plan
./scripts/terraform-with-sops.sh plan

# Apply
./scripts/terraform-with-sops.sh apply

# Destroy
./scripts/terraform-with-sops.sh destroy
```

### Applying Kubernetes Secrets

Use the wrapper script for encrypted secret files:

```bash
# Apply encrypted secret
./scripts/kubectl-with-sops.sh apply -f apps/wallabag/secret.yaml

# Regular kubectl commands work normally
./scripts/kubectl-with-sops.sh get pods
```

### Manual Decryption (for viewing)

```bash
# View decrypted Terraform secrets
sops -d secrets.tfvars

# View decrypted Kubernetes secrets
sops -d apps/wallabag/secret.yaml
```

## Security Notes

- Never commit decrypted files to git
- The wrapper scripts automatically clean up temporary decrypted files
- Only the Age public key `age19ng3apc0ayv6q7t9ru7ry8d0h4496a70ff7yxtaqvk3fmvqmgppsnvn6j4` can decrypt these files
- Keep your Age private key (`~/.config/sops/age/keys.txt`) secure

## Next Steps

1. Edit `secrets.tfvars` and add your actual API tokens:
   ```bash
   sops secrets.tfvars
   ```

2. Edit `apps/wallabag/secret.yaml` and add actual passwords:
   ```bash
   sops apps/wallabag/secret.yaml
   ```

3. Test the infrastructure deployment:
   ```bash
   ./scripts/terraform-with-sops.sh plan
   ```