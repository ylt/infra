# Infrastructure Repository

Homelab infrastructure-as-code managing a Raspberry Pi Kubernetes cluster.

## Stack

- **k0s** - Lightweight Kubernetes
- **Cilium** - CNI with eBPF (kube-proxy replacement)
- **Helmfile** - Declarative Helm deployments
- **Terraform** - Authentik identity provider configuration
- **Ansible** - Node configuration

## Cluster Topology

| Node | IP | Role | Hardware |
|------|-----|------|----------|
| node-1 | 192.168.7.128 | worker | Pi 4 |
| node-2 | 192.168.7.129 | worker | Pi 4 |
| node-3 | 192.168.7.81 | worker | Pi 4 |
| node-5 | 192.168.6.188 | controller+worker | Pi 5 |
| node-6 | 192.168.7.122 | worker | Pi 5 |

## Directory Structure

```
infra/
├── k0s/                    # Kubernetes configuration
│   ├── helmfile.yaml       # All Helm releases
│   ├── values/             # Helm values files
│   ├── charts/             # Local Helm charts
│   ├── images/             # Custom Docker images
│   ├── terraform/authentik # OAuth/OIDC providers
│   └── k0sctl.yaml         # Cluster definition
├── ansible/                # Node configuration
│   ├── hosts               # Inventory
│   └── playbooks/          # Ansible playbooks
├── docs/                   # Guides
│   ├── adding-an-app.md    # Full app deployment workflow
│   └── chart-conventions.md # Helm chart patterns
└── CLAUDE.md
```

## Quick Start

### Deploy an App

```bash
# 1. Configure auth (Terraform)
cd k0s/terraform/authentik
terraform apply

# 2. Deploy (Helmfile)
cd k0s
helmfile sync -l name=<app-name>
```

See `docs/adding-an-app.md` for the full workflow.

### Common Commands

```bash
# Helmfile
helmfile sync -l name=<release>  # Deploy specific
helmfile sync                     # Deploy all
helmfile diff                     # Preview changes

# kubectl (uses ~/.kube/config)
kubectl get pods -A
kubectl logs -n <ns> <pod>

# k0sctl (requires 1Password SSH agent)
SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" \
  k0sctl apply --config k0s/k0sctl.yaml

# Ansible
cd ansible && ansible-playbook playbooks/main.yml
```

## Key Services

| Service | URL | Purpose |
|---------|-----|---------|
| Authentik | auth.golden.wales | SSO/identity |
| Traefik | traefik.golden.wales | Ingress |
| Grafana | grafana.golden.wales | Dashboards |
| Home Assistant | home.golden.wales | Home automation |
| Longhorn | longhorn.golden.wales | Storage UI |
| Zot | zot.golden.wales | Container registry |

## Container Registry

```bash
docker login zot.golden.wales
docker build -t zot.golden.wales/my-image:latest .
docker push zot.golden.wales/my-image:latest
```

- Anonymous pulls enabled for cluster workloads
- Push requires OIDC authentication via Authentik

## Notes

- SSH uses 1Password agent - set `SSH_AUTH_SOCK` for k0sctl
- After k0s reset, reboot nodes for clean state
- Use default kubeconfig - no KUBECONFIG env var needed
