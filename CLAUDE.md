# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a homelab infrastructure-as-code repository managing a Raspberry Pi cluster running Kubernetes:

- **k0s** for lightweight Kubernetes
- **Cilium** for CNI with eBPF (kube-proxy replacement)
- **Helmfile** for declarative Helm deployments
- **Ansible** for server configuration
- **Terraform** for Authentik identity provider configuration

## Cluster Topology

| Node | IP | k0s Role | Hardware |
|------|-----|----------|----------|
| node-1 | 192.168.7.128 | worker | Pi 4 |
| node-2 | 192.168.7.129 | worker | Pi 4 |
| node-3 | 192.168.7.81 | worker | Pi 4 |
| node-5 | 192.168.6.188 | controller+worker | Pi 5 |
| node-6 | 192.168.7.122 | worker | Pi 5 |

## Directory Structure

```
infra/
├── k0s/                    # Kubernetes cluster configuration
│   ├── helmfile.yaml       # All Helm releases
│   ├── values/             # Helm values files
│   ├── charts/             # Local Helm charts
│   ├── images/             # Custom Docker images
│   ├── terraform/authentik # Authentik OAuth/OIDC providers
│   └── k0sctl.yaml         # k0s cluster definition
├── ansible/                # Server configuration
│   ├── hosts               # Inventory
│   └── playbooks/          # Ansible playbooks
└── CLAUDE.md
```

See `k0s/CLAUDE.md` for detailed k0s cluster documentation.

## Common Commands

### Helmfile (k0s/helmfile.yaml)

```bash
cd k0s

# Deploy specific release
helmfile sync -l name=<release-name>

# Deploy all
helmfile sync

# Check what would change
helmfile diff
```

### kubectl

Uses default kubeconfig at `~/.kube/config`:

```bash
kubectl get pods -A
kubectl logs -n <namespace> <pod>
kubectl get nodes
```

### k0sctl Cluster Management

```bash
# Deploy/update cluster (requires 1Password SSH agent)
SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" \
  k0sctl apply --config k0s/k0sctl.yaml

# Get kubeconfig
SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" \
  k0sctl kubeconfig --config k0s/k0sctl.yaml > ~/.kube/config
```

### Ansible

```bash
cd ansible

# Run main playbook
ansible-playbook playbooks/main.yml

# Run on specific hosts
ansible-playbook playbooks/main.yml --limit node-5
```

### Terraform (Authentik)

```bash
cd k0s/terraform/authentik
terraform plan
terraform apply
```

## Key Services

| Service | URL | Purpose |
|---------|-----|---------|
| Traefik | traefik.golden.wales | Ingress controller |
| Authentik | auth.golden.wales | SSO/identity provider |
| Zot | zot.golden.wales | Container registry |
| Grafana | grafana.golden.wales | Dashboards |
| Home Assistant | home.golden.wales | Home automation |
| Longhorn | longhorn.golden.wales | Storage UI |

## Container Registry (Zot)

Custom images are built and pushed to the internal Zot registry:

```bash
# Build and push (requires OIDC API key from UI)
docker login zot.golden.wales
docker build -t zot.golden.wales/my-image:latest .
docker push zot.golden.wales/my-image:latest
```

- **Anonymous pulls**: Enabled for cluster workloads (no imagePullSecrets needed)
- **Authenticated push**: Via OIDC with Authentik

Custom image sources live in `k0s/images/`.

## Important Notes

- SSH to nodes uses 1Password agent - set `SSH_AUTH_SOCK` for k0sctl commands
- After k0s reset, reboot nodes to ensure clean state
- Use default kubeconfig - no KUBECONFIG env var needed
- Unsafe sysctls are blocked by default - use `privileged: true` for networking workloads
