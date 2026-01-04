# Home Assistant OAuth2/OpenID Connect provider
resource "random_password" "homeassistant_client_secret" {
  length  = 64
  special = false
}

resource "authentik_provider_oauth2" "homeassistant" {
  name               = "homeassistant"
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  client_id          = "homeassistant"
  client_secret      = random_password.homeassistant_client_secret.result
  client_type        = "confidential"

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://home.golden.wales/auth/oidc/callback"
    }
  ]

  property_mappings = data.authentik_property_mapping_provider_scope.oauth2.ids
  signing_key       = data.authentik_certificate_key_pair.default.id

  access_token_validity  = "minutes=10"
  refresh_token_validity = "days=30"
}

# Home Assistant application
resource "authentik_application" "homeassistant" {
  name              = "Home Assistant"
  slug              = "home-assistant"
  group             = "Home Automation"
  protocol_provider = authentik_provider_oauth2.homeassistant.id
  meta_launch_url   = "https://home.golden.wales/auth/oidc/redirect"
  meta_icon         = "https://upload.wikimedia.org/wikipedia/en/4/49/Home_Assistant_logo_%282023%29.svg"
  open_in_new_tab   = true
}

# Output the client secret for Home Assistant configuration
output "homeassistant_client_id" {
  value = authentik_provider_oauth2.homeassistant.client_id
}

output "homeassistant_client_secret" {
  value     = random_password.homeassistant_client_secret.result
  sensitive = true
}
