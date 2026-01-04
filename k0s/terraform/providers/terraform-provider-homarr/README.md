# Terraform Provider for Homarr

A Terraform provider for managing [Homarr](https://homarr.dev) dashboard configuration.

## Requirements

- Terraform >= 1.0
- Go >= 1.21 (for building from source)
- Homarr >= 1.0

## Installation

### Local Development

1. Build the provider:
   ```bash
   go build -o terraform-provider-homarr
   ```

2. Add to `~/.terraformrc`:
   ```hcl
   provider_installation {
     dev_overrides {
       "registry.terraform.io/joe/homarr" = "/path/to/terraform-provider-homarr"
     }
     direct {}
   }
   ```

## Authentication

The provider supports two authentication methods:

| Method | Header/Cookie | Use Case |
|--------|---------------|----------|
| `api_key` | `ApiKey` header | REST API (apps, users) |
| `session_token` | `authjs.session-token` cookie | tRPC API (groups, integrations, settings) |

**Getting credentials:**

- **API Key**: Generate in Homarr UI under Settings > API Keys
- **Session Token**: Copy the `authjs.session-token` cookie value from your browser after logging in

## Provider Configuration

```hcl
terraform {
  required_providers {
    homarr = {
      source = "registry.terraform.io/joe/homarr"
    }
  }
}

provider "homarr" {
  url           = "https://homarr.example.com"
  api_key       = var.homarr_api_key       # For apps, users
  session_token = var.homarr_session_token # For groups, integrations
}
```

### Environment Variables

All provider attributes can be set via environment variables:

| Attribute | Environment Variable |
|-----------|---------------------|
| `url` | `HOMARR_URL` |
| `api_key` | `HOMARR_API_KEY` |
| `session_token` | `HOMARR_SESSION_TOKEN` |

## Resources

### homarr_app

Manages dashboard app tiles.

**Authentication:** `api_key`

```hcl
resource "homarr_app" "sonarr" {
  name        = "Sonarr"
  icon_url    = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/sonarr.png"
  url         = "https://sonarr.example.com"
  description = "TV show management"
  ping_url    = "https://sonarr.example.com/ping"
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | yes | Display name |
| `icon_url` | string | yes | URL to app icon |
| `url` | string | no | URL when clicking the app |
| `description` | string | no | App description |
| `ping_url` | string | no | URL for health checks |

---

### homarr_group

Manages user groups.

**Authentication:** `session_token`

```hcl
resource "homarr_group" "admins" {
  name = "Administrators"
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | yes | Group name |

---

### homarr_integration

Manages service integrations for widgets and monitoring.

**Authentication:** `session_token`

```hcl
resource "homarr_integration" "sonarr" {
  name    = "Sonarr"
  kind    = "sonarr"
  url     = "http://sonarr.media.svc.cluster.local:8989"
  api_key = var.sonarr_api_key
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | yes | Display name |
| `kind` | string | yes | Integration type (see below) |
| `url` | string | yes | Service URL |
| `api_key` | string | no | API key for the service |

**Supported integration kinds:**

| Category | Kinds |
|----------|-------|
| Media Management | `sonarr`, `radarr`, `lidarr`, `readarr`, `prowlarr`, `bazarr` |
| Media Servers | `jellyfin`, `plex`, `emby` |
| Download Clients | `sabnzbd`, `nzbget`, `qBittorrent`, `transmission`, `deluge` |
| Home Automation | `homeAssistant` |
| Network | `piHole`, `adGuardHome` |
| Container | `dockerHub`, `gitHubContainerRegistry`, `quay` |
| Other | `gitlab`, `npm`, `codeberg`, `linuxServerIO` |

**Note:** Changing `kind` forces resource replacement.

---

### homarr_search_engine

Manages search engines for the Homarr search bar.

**Authentication:** `session_token`

```hcl
# Generic URL-based search engine
resource "homarr_search_engine" "duckduckgo" {
  name         = "DuckDuckGo"
  short        = "ddg"
  description  = "Privacy-focused search"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/duckduckgo.svg"
  url_template = "https://duckduckgo.com/?q=%s"
}

# Integration-based search engine (search within Jellyfin, Sonarr, etc.)
resource "homarr_search_engine" "jellyfin_search" {
  type           = "fromIntegration"
  name           = "Jellyfin"
  short          = "jf"
  integration_id = homarr_integration.jellyfin.id
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `type` | string | no | `generic` (default) or `fromIntegration` |
| `name` | string | yes | Display name |
| `short` | string | yes | Keyboard shortcut (e.g., 'g' for Google) |
| `description` | string | no | Description text |
| `icon_url` | string | no | Icon URL (required for `generic` type) |
| `url_template` | string | no | URL with `%s` placeholder (required for `generic` type) |
| `integration_id` | string | no | Integration ID (required for `fromIntegration` type) |

**Note:** Changing `type` forces resource replacement.

## Kubernetes Considerations

When running Homarr in Kubernetes, integrations must use internal service URLs to bypass ingress authentication (e.g., Authentik forward auth).

```hcl
# External URL - will fail if behind forward auth
url = "https://sonarr.example.com"

# Internal URL - works from within the cluster
url = "http://sonarr.media.svc.cluster.local:8989"
```

## Example: Complete Configuration

```hcl
terraform {
  required_providers {
    homarr = {
      source = "registry.terraform.io/joe/homarr"
    }
  }
}

variable "homarr_api_key" {
  type      = string
  sensitive = true
}

variable "homarr_session_token" {
  type      = string
  sensitive = true
}

provider "homarr" {
  url           = "https://homarr.example.com"
  api_key       = var.homarr_api_key
  session_token = var.homarr_session_token
}

# Groups
resource "homarr_group" "media" {
  name = "Media Users"
}

# Integrations
resource "homarr_integration" "sonarr" {
  name    = "Sonarr"
  kind    = "sonarr"
  url     = "http://sonarr.media.svc.cluster.local:8989"
  api_key = "your-sonarr-api-key"
}

resource "homarr_integration" "radarr" {
  name    = "Radarr"
  kind    = "radarr"
  url     = "http://radarr.media.svc.cluster.local:7878"
  api_key = "your-radarr-api-key"
}

resource "homarr_integration" "jellyfin" {
  name    = "Jellyfin"
  kind    = "jellyfin"
  url     = "http://jellyfin.media.svc.cluster.local:8096"
  api_key = "your-jellyfin-api-key"
}

# Apps
resource "homarr_app" "sonarr" {
  name        = "Sonarr"
  icon_url    = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/sonarr.png"
  url         = "https://sonarr.example.com"
  description = "TV Shows"
}
```

## Import

All resources support import by ID:

```bash
terraform import homarr_app.example <app-id>
terraform import homarr_group.example <group-id>
terraform import homarr_integration.example <integration-id>
terraform import homarr_search_engine.example <search-engine-id>
```

## Troubleshooting

### "Missing Session Token" error
Integrations and groups require `session_token` authentication. Ensure it's configured in the provider.

### "Unable to connect to the integration" error
Homarr validates connectivity during integration creation. Common causes:
- URL is behind authentication (use internal Kubernetes URL)
- Service is not running
- Wrong port number

### Integration created but not visible
If using external URLs behind forward auth, Homarr may receive an HTML login page instead of JSON. Use internal service URLs.

## Development

```bash
# Build
go build -o terraform-provider-homarr

# Test
cd examples/provider
terraform init
terraform plan
terraform apply
```

## License

MIT
