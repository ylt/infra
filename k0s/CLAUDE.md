# CLAUDE.md

This file provides guidance to Claude Code when working with the k0s Kubernetes cluster.

## Overview

This is a k0s-based Kubernetes cluster managed with Helmfile. The cluster runs various self-hosted services including home automation, authentication, monitoring, and networking tools.

## Architecture

### Deployment Method

- **Helmfile** (`helmfile.yaml`) manages all Helm releases
- Local charts live in `charts/` directory
- Values files live in `values/` directory
- Terraform for Authentik configuration in `terraform/authentik/`

### Key Components

| Component | Purpose |
|-----------|---------|
| Traefik | Ingress controller with Authentik forward auth |
| Longhorn | Distributed storage (CSI) |
| Authentik | SSO/identity provider |
| Zot | Container registry at `zot.golden.wales` |
| Loki + Alloy | Log aggregation |
| Grafana | Dashboards and visualization |

### Container Registry (Zot)

Custom images are built and pushed to the internal Zot registry:

```bash
# Build and push
docker build -t zot.golden.wales/my-image:latest .
docker push zot.golden.wales/my-image:latest

# Pull (anonymous read enabled)
image: zot.golden.wales/my-image:latest
```

- **Anonymous pulls**: Enabled for cluster workloads (no imagePullSecrets needed)
- **Authenticated push**: Via OIDC with Authentik (generate API key from UI)
- **UI**: https://zot.golden.wales (Authentik login)

Custom images live in `images/` directory.

## Common Commands

```bash
# Deploy specific release
helmfile sync -l name=<release-name>

# Deploy all
helmfile sync

# Check what would change
helmfile diff

# Template locally
helmfile template -l name=<release-name>
```

## k0s-Specific Notes

### Unsafe Sysctls Are Blocked

By default, kubelet blocks unsafe sysctls like `net.ipv4.ip_forward`. Pods requesting these via `securityContext.sysctls` will fail with `SysctlForbidden`.

**Workarounds:**
1. Use `privileged: true` instead (simpler, used for vpn-gateway)
2. Configure kubelet to allow specific sysctls in k0s.yaml:
   ```yaml
   spec:
     workerProfiles:
       - name: default
         values:
           allowedUnsafeSysctls:
             - net.ipv4.ip_forward
   ```

### Default Kubeconfig

Use the default kubeconfig, not a named one:
```bash
kubectl get pods  # Correct
KUBECONFIG=~/.kube/k0s-config kubectl get pods  # Wrong
```

### Privileged Containers

For networking workloads that need:
- IP forwarding (`/proc/sys/net/ipv4/ip_forward`)
- iptables/NAT rules
- Raw network access

Use `privileged: true` in securityContext rather than trying to use sysctls.

## Service Patterns

### Ingress with Authentik Forward Auth

Protected services use the authentik middleware:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
spec:
  routes:
    - match: Host(`app.golden.wales`)
      middlewares:
        - name: authentik
          namespace: traefik
      services:
        - name: app
          port: 8080
```

### Services with Native OIDC

Apps with built-in OIDC (like Zot) bypass forward auth:

1. Create OAuth2 provider in `terraform/authentik/`
2. Configure app with OIDC settings
3. Use simple IngressRoute without authentik middleware

## Directory Structure

```
k0s/
├── helmfile.yaml           # All Helm releases
├── k0sctl.yaml             # k0s cluster definition
├── values/                 # Helm values files
├── charts/                 # Local Helm charts
│   ├── cluster-config/     # Cluster-wide resources (certs, ingress, middleware)
│   ├── vpn-gateway/        # L2TP VPN egress gateway
│   ├── homeassistant/
│   ├── mosquitto/
│   ├── zigbee2mqtt/
│   ├── govee2mqtt/
│   ├── node-red/
│   ├── postgres/
│   └── cloudflared/
├── images/                 # Custom Docker images
│   └── vpn-gateway/        # L2TP gateway image
└── terraform/
    └── authentik/          # Authentik OAuth providers, apps, policies
```
