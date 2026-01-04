terraform {
  required_providers {
    homarr = {
      source = "local/joe/homarr"
    }
  }
}

provider "homarr" {
  url           = "https://homarr.golden.wales"
  api_key       = var.homarr_api_key
  session_token = var.homarr_session_token
}

variable "homarr_api_key" {
  type      = string
  sensitive = true
}

variable "homarr_session_token" {
  type      = string
  sensitive = true
}

# Example integrations - use variables for API keys
variable "sonarr_api_key" {
  type      = string
  sensitive = true
  default   = "your-sonarr-api-key"
}

variable "radarr_api_key" {
  type      = string
  sensitive = true
  default   = "your-radarr-api-key"
}

variable "prowlarr_api_key" {
  type      = string
  sensitive = true
  default   = "your-prowlarr-api-key"
}

variable "jellyfin_api_key" {
  type      = string
  sensitive = true
  default   = "your-jellyfin-api-key"
}

# Integrations - use FQDN internal service names to bypass forward auth
resource "homarr_integration" "sonarr" {
  name    = "Sonarr"
  kind    = "sonarr"
  url     = "http://sonarr.media.svc.cluster.local:8989"
  api_key = var.sonarr_api_key
}

resource "homarr_integration" "radarr" {
  name    = "Radarr"
  kind    = "radarr"
  url     = "http://radarr.media.svc.cluster.local:7878"
  api_key = var.radarr_api_key
}

resource "homarr_integration" "prowlarr" {
  name    = "Prowlarr"
  kind    = "prowlarr"
  url     = "http://prowlarr.media.svc.cluster.local:9696"
  api_key = var.prowlarr_api_key
}

resource "homarr_integration" "jellyfin" {
  name    = "Jellyfin"
  kind    = "jellyfin"
  url     = "http://jellyfin.media.svc.cluster.local:8096"
  api_key = var.jellyfin_api_key
}
