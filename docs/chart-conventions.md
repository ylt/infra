# Helm Chart Conventions

This repository uses the **k8s-at-home common library** for most application charts. This provides a consistent structure and reduces boilerplate.

## Common Library Overview

The common library (`k0s/charts/common/`) is a Helm library chart that generates Kubernetes resources from a standardized values structure.

**Key benefits:**
- Single template file per chart
- Consistent resource naming and labels
- Built-in support for persistence, ingress, probes, and more
- Easy to add new apps

## Chart Structure

```
k0s/charts/myapp/
├── Chart.yaml              # Chart metadata + common dependency
└── templates/
    └── common.yaml         # Single line: {{ include "common.all" . }}
```

### Chart.yaml

```yaml
apiVersion: v2
name: myapp
description: My application description
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: common
    version: 4.5.2
    repository: file://../common
```

### templates/common.yaml

```yaml
{{ include "common.all" . }}
```

That's it! All Kubernetes resources are generated from values.

## Values Structure

### Image

```yaml
image:
  repository: lscr.io/linuxserver/myapp
  tag: latest
  pullPolicy: IfNotPresent
```

### Environment Variables

```yaml
# Simple values
env:
  TZ: Europe/London
  PUID: "1000"
  PGID: "1000"

# From secrets/configmaps
env:
  DATABASE_URL:
    valueFrom:
      secretKeyRef:
        name: myapp-secrets
        key: database-url
```

### Service

```yaml
service:
  main:
    enabled: true
    type: ClusterIP  # or LoadBalancer
    ports:
      http:
        enabled: true
        port: 8080
        primary: true
      # Additional ports
      api:
        enabled: true
        port: 9000

# Disable default http port
service:
  main:
    ports:
      http:
        enabled: false
      mqtt:
        enabled: true
        port: 1883
        primary: true
```

### Ingress (Standard Kubernetes)

```yaml
ingress:
  main:
    enabled: true
    ingressClassName: traefik
    annotations:
      # For forward-auth apps
      traefik.ingress.kubernetes.io/router.middlewares: traefik-authentik@kubernetescrd
    hosts:
      - host: myapp.golden.wales
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts:
          - myapp.golden.wales
```

### Persistence

```yaml
persistence:
  # PVC (most common)
  config:
    enabled: true
    type: pvc
    storageClass: longhorn
    size: 10Gi
    mountPath: /config
    accessMode: ReadWriteOnce

  # Existing PVC
  media:
    enabled: true
    type: pvc
    existingClaim: media-storage
    mountPath: /media

  # ConfigMap mount
  config-file:
    enabled: true
    type: configMap
    name: myapp-config
    mountPath: /app/config.yaml
    subPath: config.yaml

  # Host path (use sparingly)
  device:
    enabled: true
    type: hostPath
    hostPath: /dev/ttyUSB0
    mountPath: /dev/ttyUSB0
```

### ConfigMap Generation

```yaml
configmap:
  config:
    enabled: true
    data:
      config.yaml: |
        setting: value
        another: setting
```

### Resources

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Scheduling

```yaml
nodeSelector:
  kubernetes.io/arch: arm64

tolerations:
  - key: node-type
    operator: Equal
    value: hyperv
    effect: NoSchedule

affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - node-5
```

### Security Context

```yaml
# Pod-level
podSecurityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000

# Container-level
securityContext:
  privileged: true  # For hardware access
  capabilities:
    add:
      - NET_ADMIN
```

### Probes

```yaml
probes:
  liveness:
    enabled: true
    spec:
      httpGet:
        path: /health
        port: http
      initialDelaySeconds: 30
      periodSeconds: 10

  readiness:
    enabled: true
    spec:
      httpGet:
        path: /ready
        port: http

  startup:
    enabled: false
```

### Init Containers

```yaml
initContainers:
  fix-permissions:
    image: busybox:latest
    command:
      - sh
      - -c
      - chown -R 1000:1000 /config
    volumeMounts:
      - name: config
        mountPath: /config
```

## Custom Templates

For resources not covered by the common library, add additional templates alongside `common.yaml`:

```
k0s/charts/myapp/
├── Chart.yaml
└── templates/
    ├── common.yaml           # Standard resources
    ├── vault-auth.yaml       # Custom: Vault authentication
    └── vault-static-secret.yaml  # Custom: Vault secret sync
```

Example custom template for Vault integration:

```yaml
# templates/vault-auth.yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: {{ include "common.names.fullname" . }}
spec:
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: {{ include "common.names.fullname" . }}
    serviceAccount: {{ include "common.names.fullname" . }}
```

## When NOT to Use Common Library

Don't use the common library for:

- **cluster-config** - Contains only raw Kubernetes resources (certificates, secrets, middleware)
- **vpn-gateway** - Complex networking with custom deployment logic
- **External charts** - Use upstream charts (Authentik, Grafana, Longhorn, etc.)

## Complete Example

```yaml
# k0s/values/myapp.yaml
image:
  repository: lscr.io/linuxserver/myapp
  tag: latest

env:
  TZ: Europe/London
  PUID: "1000"
  PGID: "1000"

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
    size: 5Gi
    mountPath: /config

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

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```
