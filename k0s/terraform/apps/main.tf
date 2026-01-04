# Authentik data sources
data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-authentication-flow" {
  slug = "default-authentication-flow"
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_certificate_key_pair" "default" {
  name = "authentik Self-signed Certificate"
}

data "authentik_property_mapping_provider_scope" "oauth2" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

# Common values passed to all app modules
locals {
  authentik_defaults = {
    authorization_flow_id   = data.authentik_flow.default-authorization-flow.id
    authentication_flow_id  = data.authentik_flow.default-authentication-flow.id
    invalidation_flow_id    = data.authentik_flow.default-invalidation-flow.id
    signing_key_id          = data.authentik_certificate_key_pair.default.id
    property_mapping_ids    = data.authentik_property_mapping_provider_scope.oauth2.ids
  }
}
