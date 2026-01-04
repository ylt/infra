# Forward auth proxy provider
resource "authentik_provider_proxy" "this" {
  count = var.create_authentik_app && var.auth_mode == "forward_auth" ? 1 : 0

  name               = var.slug
  mode               = "forward_single"
  authorization_flow = var.authentik_authorization_flow_id
  invalidation_flow  = var.authentik_invalidation_flow_id
  external_host      = var.external_url
}

# OAuth2 provider
resource "authentik_provider_oauth2" "this" {
  count = var.create_authentik_app && var.auth_mode == "oauth" ? 1 : 0

  name               = var.slug
  authorization_flow = var.authentik_authorization_flow_id
  invalidation_flow  = var.authentik_invalidation_flow_id
  client_id          = var.slug
  client_type        = "confidential"
  signing_key        = var.authentik_signing_key_id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "${var.external_url}${var.oauth_redirect_path}"
    }
  ]

  property_mappings = var.authentik_property_mapping_ids

  access_token_validity  = "hours=24"
  refresh_token_validity = "days=30"
}

# LDAP provider
resource "authentik_provider_ldap" "this" {
  count = var.create_authentik_app && var.auth_mode == "ldap" ? 1 : 0

  name        = var.slug
  base_dn     = var.ldap_base_dn
  bind_flow   = var.authentik_authentication_flow_id
  unbind_flow = var.authentik_invalidation_flow_id
  certificate = var.authentik_signing_key_id
}

# Authentik application
locals {
  provider_id = (
    var.auth_mode == "forward_auth" ? (length(authentik_provider_proxy.this) > 0 ? authentik_provider_proxy.this[0].id : null) :
    var.auth_mode == "oauth" ? (length(authentik_provider_oauth2.this) > 0 ? authentik_provider_oauth2.this[0].id : null) :
    var.auth_mode == "ldap" ? (length(authentik_provider_ldap.this) > 0 ? authentik_provider_ldap.this[0].id : null) :
    null
  )
  effective_launch_url = coalesce(var.launch_url, var.external_url)
}

resource "authentik_application" "this" {
  count = var.create_authentik_app ? 1 : 0

  name  = var.name
  slug  = var.slug
  group = var.group

  protocol_provider = local.provider_id

  meta_launch_url = local.effective_launch_url
  meta_icon       = var.icon_url != "" ? var.icon_url : null
  open_in_new_tab = true
}

# Homarr tile
resource "homarr_app" "this" {
  count = var.create_homarr_tile ? 1 : 0

  name        = var.name
  url         = local.effective_launch_url
  icon_url    = var.icon_url
  description = var.description
  ping_url    = var.internal_url
}

# Homarr integration
# Most integrations require an API key - only create when provided
locals {
  # Integrations that work without API key (most need credentials)
  no_api_key_kinds = []
  needs_api_key    = var.integration_kind != null && !contains(local.no_api_key_kinds, var.integration_kind)
  has_api_key      = var.api_key != null && var.api_key != ""
}

resource "homarr_integration" "this" {
  count = var.create_homarr_integration && var.integration_kind != null && (!local.needs_api_key || local.has_api_key) ? 1 : 0

  name    = var.name
  kind    = var.integration_kind
  url     = var.internal_url
  api_key = var.api_key
}

# Homarr search engine
resource "homarr_search_engine" "this" {
  count = var.create_homarr_search_engine ? 1 : 0

  name         = var.name
  short        = coalesce(var.search_short, substr(var.slug, 0, 8))
  description  = var.description
  url_template = coalesce(var.search_url_template, "${var.external_url}/search?q=%s")
  icon_url     = var.icon_url
}
