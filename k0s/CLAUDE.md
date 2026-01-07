# k0s Cluster Documentation

## Overview

k0s-based Kubernetes cluster managed with Helmfile. Runs self-hosted services including home automation, media, authentication, and monitoring.

## Architecture

| Component | Purpose |
|-----------|---------|
| Traefik | Ingress controller |
| Authentik | SSO/identity provider (OAuth2, LDAP, forward-auth) |
| Longhorn | Distributed block storage (CSI) |
| Zot | Container registry at `zot.golden.wales` |
| Loki + Alloy | Log aggregation |
| Grafana | Dashboards |

## Adding Apps

**Both Terraform AND Helm are required** when adding new apps:
1. **Terraform** - Configure authentication in `terraform/authentik/`
2. **Helm** - Deploy the application via `helmfile.yaml`

See `docs/adding-an-app.md` for the complete workflow.

## Chart Conventions

Most apps use the **k8s-at-home common library**:

```yaml
# Chart.yaml
dependencies:
  - name: common
    version: 4.5.2
    repository: file://../common

# templates/common.yaml
{{ include "common.all" . }}
```

See `docs/chart-conventions.md` for the full values structure.

## Ingress Patterns

### Standard Ingress with Authentik (forward-auth)

For apps without native authentication:

```yaml
ingress:
  main:
    enabled: true
    ingressClassName: traefik
    annotations:
      traefik.ingress.kubernetes.io/router.middlewares: traefik-authentik@kubernetescrd
    hosts:
      - host: app.golden.wales
        paths:
          - path: /
    tls:
      - hosts:
          - app.golden.wales
```

### Standard Ingress (OAuth2 apps)

For apps with built-in OAuth2/OIDC (Grafana, Zot, etc.):

```yaml
ingress:
  main:
    enabled: true
    ingressClassName: traefik
    hosts:
      - host: app.golden.wales
        paths:
          - path: /
    tls:
      - hosts:
          - app.golden.wales
```

## Common Commands

```bash
# Deploy specific release
helmfile sync -l name=<release-name>

# Deploy all
helmfile sync

# Check changes
helmfile diff

# Template locally
helmfile template -l name=<release-name>
```

## Directory Structure

```
k0s/
├── helmfile.yaml       # All Helm releases
├── k0sctl.yaml         # k0s cluster definition
├── values/             # Helm values (*.yaml) and secrets (*-secrets.yaml)
├── charts/             # Local Helm charts
│   ├── common/         # k8s-at-home library chart
│   ├── cluster-config/ # Cluster resources (certs, middleware)
│   └── */              # Application charts
├── images/             # Custom Docker images
└── terraform/
    └── authentik/      # Authentik OAuth/OIDC configuration
```

## Container Registry (Zot)

```bash
# Build and push (requires OIDC API key from UI)
docker login zot.golden.wales
docker build -t zot.golden.wales/my-image:latest .
docker push zot.golden.wales/my-image:latest
```

- **Anonymous pulls**: Enabled for cluster workloads
- **Authenticated push**: Via OIDC with Authentik

## k0s-Specific Notes

### Privileged Containers

For networking workloads needing IP forwarding, iptables, or raw network access, use `privileged: true` in securityContext. Unsafe sysctls are blocked by default.

### Default Kubeconfig

Use the default kubeconfig at `~/.kube/config`:

```bash
kubectl get pods       # Correct
KUBECONFIG=... kubectl # Wrong
```
