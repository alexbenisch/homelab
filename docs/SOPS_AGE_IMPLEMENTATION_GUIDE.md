# SOPS and Age Implementation Guide

This guide walks through securing Kubernetes secrets using SOPS (Secrets OPerationS) with age encryption for your homelab GitOps setup.

## Overview

SOPS encrypts values in YAML/JSON files while keeping the structure readable. Age provides modern, secure encryption with simple key management.

## Prerequisites

- Linux system with curl and tar
- Kubernetes cluster with Flux GitOps
- Git repository with Kubernetes manifests

## 1. Install Required Tools

### Install age
```bash
curl -L https://github.com/FiloSottile/age/releases/latest/download/age-v1.1.1-linux-amd64.tar.gz | tar xz
sudo mv age/age* /usr/local/bin/
```

### Install SOPS
```bash
curl -LO https://github.com/mozilla/sops/releases/latest/download/sops-v3.8.1.linux.amd64
sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops
```

### Verify Installation
```bash
age --version
sops --version
```

## 2. Generate Age Key Pair

```bash
# Create SOPS config directory
mkdir -p ~/.config/sops/age

# Generate age key pair
age-keygen -o ~/.config/sops/age/keys.txt
```

**Important**: Save the public key (starts with `age1...`) displayed in the output.

## 3. Configure SOPS

Create `.sops.yaml` in your repository root:

```yaml
creation_rules:
  - path_regex: .*secret\.yaml$
    age: age1your_public_key_here
  - path_regex: apps/.*/.*secret.*\.yaml$
    age: age1your_public_key_here
```

Replace `age1your_public_key_here` with your actual public key.

## 4. Set Environment Variable

Add to your shell profile (`~/.bashrc`, `~/.zshrc`):

```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
```

## 5. Encrypt Existing Secrets

### Backup Current Secrets
```bash
cp apps/wallabag/secret.yaml apps/wallabag/secret.yaml.bak
```

### Update Secret Values
Before encrypting, replace placeholder values in `apps/wallabag/secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wallabag-secrets
  namespace: wallabag
type: Opaque
stringData:
  postgres-password: "your_actual_secure_password"
  wallabag-secret: "your_actual_wallabag_secret_key"
```

### Encrypt with SOPS
```bash
sops -e -i apps/wallabag/secret.yaml
```

## 6. Working with Encrypted Secrets

### View Encrypted File
```bash
cat apps/wallabag/secret.yaml
```

### Edit Encrypted File
```bash
sops apps/wallabag/secret.yaml
```

### Decrypt for Viewing
```bash
sops -d apps/wallabag/secret.yaml
```

### Create New Encrypted Secret
```bash
sops secret-new.yaml
```

## 7. Configure Flux for SOPS

If using Flux v2, create a secret with your age key:

```bash
kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey=~/.config/sops/age/keys.txt
```

Update your Flux Kustomization to enable decryption:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: wallabag
  namespace: flux-system
spec:
  # ... other fields
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

## 8. Security Best Practices

### Key Management
- Store the private key (`~/.config/sops/age/keys.txt`) securely
- Never commit private keys to git
- Consider using multiple keys for different environments
- Backup your private key securely

### Git Configuration
Add to `.gitignore`:
```
# SOPS keys
*.agekey
keys.txt
```

### File Patterns
- Use consistent naming: `*secret*.yaml`, `secrets.yaml`
- Encrypt entire files, not individual values
- Keep non-sensitive config separate from secrets

## 9. Verification

### Test Decryption
```bash
sops -d apps/wallabag/secret.yaml | kubectl apply --dry-run=client -f -
```

### Verify Flux Integration
```bash
kubectl get secrets -n wallabag
kubectl describe secret wallabag-secrets -n wallabag
```

## Troubleshooting

### Common Issues

1. **"no matching creation rule"**: Check `.sops.yaml` path patterns
2. **"failed to get the data key"**: Verify `SOPS_AGE_KEY_FILE` environment variable
3. **Flux decryption fails**: Ensure sops-age secret exists in flux-system namespace

### Debug Commands
```bash
# Check SOPS configuration
sops --version
echo $SOPS_AGE_KEY_FILE

# Test age key
age --version
cat ~/.config/sops/age/keys.txt | head -1
```

## Next Steps

1. Encrypt all existing secret files
2. Update CI/CD pipelines to handle SOPS
3. Document key rotation procedures
4. Consider implementing automated secret rotation