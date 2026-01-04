# Zot Registry OAuth2/OpenID Connect provider
resource "random_password" "zot_client_secret" {
  length  = 64
  special = false
}

resource "authentik_provider_oauth2" "zot" {
  name               = "zot-registry"
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  client_id          = "zot"
  client_secret      = random_password.zot_client_secret.result
  client_type        = "confidential"
  signing_key        = data.authentik_certificate_key_pair.default.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://zot.golden.wales/zot/auth/callback/oidc"
    }
  ]

  property_mappings = data.authentik_property_mapping_provider_scope.oauth2.ids

  access_token_validity  = "hours=24"
  refresh_token_validity = "days=30"
}

# Zot application (separate from forward-auth app)
resource "authentik_application" "zot_oidc" {
  name              = "Zot Registry"
  slug              = "zot-oidc"
  group             = "Infrastructure"
  protocol_provider = authentik_provider_oauth2.zot.id
  meta_launch_url   = "https://zot.golden.wales/zot/auth/login?callback_ui=https://zot.golden.wales/home&provider=oidc"
  meta_icon         = "https://zotregistry.dev/assets/images/logo.png"
  open_in_new_tab   = true
}

# Output the client credentials
output "zot_client_id" {
  value = authentik_provider_oauth2.zot.client_id
}

output "zot_client_secret" {
  value     = random_password.zot_client_secret.result
  sensitive = true
}
