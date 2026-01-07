# Adding a New App

Adding a new application to the cluster requires **both** Terraform (for authentication) **and** Helm (for deployment). This guide walks through the complete workflow.

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Adding a New App                              │
├─────────────────────────────────────────────────────────────────┤
│  1. Terraform (Authentik)  →  Configure authentication          │
│  2. Helm Chart             →  Create or choose chart             │
│  3. Helmfile               →  Add release configuration          │
│  4. Deploy                 →  terraform apply + helmfile sync    │
└─────────────────────────────────────────────────────────────────┘
```

## Step 1: Configure Authentication (Terraform)

All apps need authentication configured in `k0s/terraform/authentik/`. Choose the pattern based on your app's capabilities:

### Option A: Forward-Auth (Apps without native auth)

For apps that don't have built-in authentication (Node-RED, Zigbee2MQTT, etc.), use forward-auth. Traefik handles authentication before requests reach the app.

**Add to `forward-auth.tf`:**

```hcl
locals {
  protected_apps = {
    # ... existing apps ...

    "myapp" = {
      name  = "My App"
      url   = "https://myapp.golden.wales"
      icon  = "https://example.com/icon.png"
      group = "Category"  # e.g., "Home Automation", "Media", "Infrastructure"
    }
  }
}
```

That's it! The `for_each` loop creates the proxy provider and application automatically.

### Option B: OAuth2/OIDC (Apps with native auth)

For apps with built-in OAuth2/OIDC support (Grafana, Zot, etc.), create a dedicated `.tf` file.

**Create `myapp.tf`:**

```hcl
# Generate client secret
resource "random_password" "myapp_client_secret" {
  length  = 64
  special = false
}

# OAuth2 provider
resource "authentik_provider_oauth2" "myapp" {
  name               = "myapp"
  client_id          = "myapp"
  client_secret      = random_password.myapp_client_secret.result
  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id

  allowed_redirect_uris = [
    { matching_mode = "strict", url = "https://myapp.golden.wales/oauth2/callback" }
  ]

  property_mappings     = data.authentik_property_mapping_provider_scope.oauth2.ids
  access_token_validity = "hours=24"
  signing_key           = data.authentik_certificate_key_pair.generated.id
}

# Application
resource "authentik_application" "myapp" {
  name              = "My App"
  slug              = "myapp"
  protocol_provider = authentik_provider_oauth2.myapp.id
  meta_launch_url   = "https://myapp.golden.wales"
  meta_icon         = "https://example.com/icon.png"
  group             = "Category"
}

# Outputs for Helm values
output "myapp_client_id" {
  value = authentik_provider_oauth2.myapp.client_id
}

output "myapp_client_secret" {
  value     = random_password.myapp_client_secret.result
  sensitive = true
}
```

### Option C: LDAP (Apps requiring directory access)

For apps that need LDAP (Jellyfin, etc.), see `jellyfin.tf` as a reference.

## Step 2: Create Helm Chart

### Using the Common Library (Recommended)

Most apps use the k8s-at-home common library. See [chart-conventions.md](chart-conventions.md) for details.

**Create chart structure:**

```
k0s/charts/myapp/
├── Chart.yaml
└── templates/
    └── common.yaml
```

**Chart.yaml:**

```yaml
apiVersion: v2
name: myapp
description: My application
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: common
    version: 4.5.2
    repository: file://../common
```

**templates/common.yaml:**

```yaml
{{ include "common.all" . }}
```

**Create values file `k0s/values/myapp.yaml`:**

```yaml
image:
  repository: myimage/myapp
  tag: latest

env:
  TZ: Europe/London

service:
  main:
    ports:
      http:
        port: 8080

persistence:
  config:
    enabled: true
    type: pvc
    storageClass: longhorn
    size: 1Gi
    mountPath: /config

# For forward-auth apps
ingress:
  main:
    enabled: true
    ingressClassName: traefik
    annotations:
      traefik.ingress.kubernetes.io/router.middlewares: traefik-authentik@kubernetescrd
    hosts:
      - host: myapp.golden.wales
        paths:
          - path: /
    tls:
      - hosts:
          - myapp.golden.wales

# For OAuth2 apps (no middleware needed)
# ingress:
#   main:
#     enabled: true
#     ingressClassName: traefik
#     hosts:
#       - host: myapp.golden.wales
#         paths:
#           - path: /
#     tls:
#       - hosts:
#           - myapp.golden.wales
```

### Using External Charts

For complex apps (Authentik, Grafana, etc.), use upstream Helm charts. Add the repo to `helmfile.yaml` and configure via values.

## Step 3: Add to Helmfile

**Add release to `k0s/helmfile.yaml`:**

```yaml
  - name: myapp
    namespace: myapp
    createNamespace: true
    chart: ./charts/myapp
    needs:
      - longhorn-system/longhorn    # If using persistent storage
      - traefik/traefik             # If using ingress
      - cert-manager/cluster-config # For TLS certificates
    values:
      - values/myapp.yaml
      - values/myapp-secrets.yaml   # If secrets needed
```

**For OAuth2 apps, create secrets file `k0s/values/myapp-secrets.yaml`:**

```yaml
# DO NOT COMMIT - add to .gitignore pattern
env:
  OAUTH_CLIENT_ID: "myapp"
  OAUTH_CLIENT_SECRET: "<from terraform output>"
```

## Step 4: Deploy

```bash
# Apply Terraform changes
cd k0s/terraform/authentik
terraform apply

# Update Helm dependencies (for new charts)
cd k0s/charts/myapp
helm dependency update

# Deploy via Helmfile
cd k0s
helmfile sync -l name=myapp
```

## Quick Reference

| Auth Type | Terraform File | Ingress Middleware | App Config |
|-----------|---------------|-------------------|------------|
| Forward-auth | `forward-auth.tf` (add to locals) | `traefik-authentik@kubernetescrd` | None needed |
| OAuth2/OIDC | New `myapp.tf` | None | OIDC settings |
| LDAP | New `myapp.tf` + outpost | None/Optional | LDAP settings |

## Common Pitfalls

1. **Forgot Terraform** - App deploys but no SSO. Run `terraform apply`.
2. **Wrong redirect URI** - OAuth2 fails. Check exact URL matches.
3. **Missing middleware annotation** - Forward-auth not working. Add annotation to ingress.
4. **Secrets not in .gitignore** - Check `k0s/values/*-secrets.yaml` pattern is ignored.
