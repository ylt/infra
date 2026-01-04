variable "authentik_token" {
  description = "Authentik API token"
  type        = string
  sensitive   = true
}

variable "homarr_api_key" {
  description = "Homarr API key"
  type        = string
  sensitive   = true
}

variable "homarr_session_token" {
  description = "Homarr session token (for integrations)"
  type        = string
  sensitive   = true
}

# API keys for integrations
variable "sonarr_api_key" {
  description = "Sonarr API key"
  type        = string
  default     = null
  sensitive   = true
}

variable "radarr_api_key" {
  description = "Radarr API key"
  type        = string
  default     = null
  sensitive   = true
}

variable "prowlarr_api_key" {
  description = "Prowlarr API key"
  type        = string
  default     = null
  sensitive   = true
}

variable "jellyfin_api_key" {
  description = "Jellyfin API key"
  type        = string
  default     = null
  sensitive   = true
}

variable "jellyseerr_api_key" {
  description = "Jellyseerr API key"
  type        = string
  default     = null
  sensitive   = true
}

variable "homeassistant_api_key" {
  description = "Home Assistant long-lived access token"
  type        = string
  default     = null
  sensitive   = true
}

# For migration - preserves existing LDAP bind password
variable "jellyfin_ldap_bind_password" {
  description = "Jellyfin LDAP bind password (leave null to generate new)"
  type        = string
  default     = null
  sensitive   = true
}
