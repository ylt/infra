# Homarr OAuth2/OpenID Connect provider
resource "random_password" "homarr_client_secret" {
  length  = 64
  special = false
}

resource "authentik_provider_oauth2" "homarr" {
  name               = "homarr"
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  client_id          = "homarr"
  client_secret      = random_password.homarr_client_secret.result
  client_type        = "confidential"
  signing_key        = data.authentik_certificate_key_pair.default.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://homarr.golden.wales/api/auth/callback/oidc"
    }
  ]

  property_mappings = data.authentik_property_mapping_provider_scope.oauth2.ids

  access_token_validity  = "hours=24"
  refresh_token_validity = "days=30"
}

resource "authentik_application" "homarr" {
  name              = "Homarr"
  slug              = "homarr"
  group             = "Infrastructure"
  protocol_provider = authentik_provider_oauth2.homarr.id
  meta_launch_url   = "https://homarr.golden.wales"
  meta_icon         = "https://homarr.dev/img/logo.png"
  open_in_new_tab   = true
}

output "homarr_client_id" {
  value = authentik_provider_oauth2.homarr.client_id
}

output "homarr_client_secret" {
  value     = random_password.homarr_client_secret.result
  sensitive = true
}
