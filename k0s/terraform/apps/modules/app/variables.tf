variable "name" {
  description = "Display name for the app"
  type        = string
}

variable "slug" {
  description = "URL-safe identifier (used in authentik slug, homarr ID)"
  type        = string
}

variable "external_url" {
  description = "Public URL for the app (base for OAuth redirects)"
  type        = string
}

variable "launch_url" {
  description = "URL when clicking app (defaults to external_url)"
  type        = string
  default     = null
}

variable "internal_url" {
  description = "Internal cluster URL (for homarr ping/integration)"
  type        = string
  default     = null
}

variable "icon_url" {
  description = "URL to app icon"
  type        = string
}

variable "group" {
  description = "App group in Authentik"
  type        = string
  default     = null
}

variable "description" {
  description = "App description for Homarr"
  type        = string
  default     = null
}

# Auth mode
variable "auth_mode" {
  description = "Authentication mode: forward_auth, oauth, ldap, or none"
  type        = string
  default     = "forward_auth"

  validation {
    condition     = contains(["forward_auth", "oauth", "ldap", "none"], var.auth_mode)
    error_message = "auth_mode must be forward_auth, oauth, ldap, or none"
  }
}

# OAuth-specific
variable "oauth_redirect_path" {
  description = "OAuth callback path (appended to external_url)"
  type        = string
  default     = "/oauth/callback"
}

# LDAP-specific
variable "ldap_base_dn" {
  description = "LDAP base DN (e.g., dc=ldap,dc=example,dc=com)"
  type        = string
  default     = null
}

# Homarr integration
variable "integration_kind" {
  description = "Homarr integration type (sonarr, radarr, jellyfin, etc.)"
  type        = string
  default     = null
}

variable "api_key" {
  description = "API key for Homarr integration"
  type        = string
  default     = null
  sensitive   = true
}

# Feature flags
variable "create_authentik_app" {
  description = "Create Authentik application"
  type        = bool
  default     = true
}

variable "create_homarr_tile" {
  description = "Create Homarr dashboard tile"
  type        = bool
  default     = true
}

variable "create_homarr_integration" {
  description = "Create Homarr integration for widgets"
  type        = bool
  default     = false
}

variable "create_homarr_search_engine" {
  description = "Create Homarr search engine"
  type        = bool
  default     = false
}

variable "search_url_template" {
  description = "Search URL template with %s placeholder for query"
  type        = string
  default     = null
}

variable "search_short" {
  description = "Short name for search engine (max 8 chars)"
  type        = string
  default     = null
}

# Passed from root module
variable "authentik_authorization_flow_id" {
  description = "Authentik authorization flow ID"
  type        = string
  default     = null
}

variable "authentik_authentication_flow_id" {
  description = "Authentik authentication flow ID (for LDAP bind)"
  type        = string
  default     = null
}

variable "authentik_invalidation_flow_id" {
  description = "Authentik invalidation flow ID"
  type        = string
  default     = null
}

variable "authentik_signing_key_id" {
  description = "Authentik certificate key pair ID for signing"
  type        = string
  default     = null
}

variable "authentik_property_mapping_ids" {
  description = "OAuth2 property mapping IDs"
  type        = list(string)
  default     = []
}
