# Grafana OAuth2/OpenID Connect provider
resource "random_password" "grafana_client_secret" {
  length  = 64
  special = false
}

resource "authentik_provider_oauth2" "grafana" {
  name               = "grafana"
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  client_id          = "grafana"
  client_secret      = random_password.grafana_client_secret.result
  client_type        = "confidential"
  signing_key        = data.authentik_certificate_key_pair.default.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://grafana.golden.wales/login/generic_oauth"
    }
  ]

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.oauth2.ids,
    [authentik_property_mapping_provider_scope.groups.id]
  )

  access_token_validity  = "minutes=10"
  refresh_token_validity = "days=30"
}

# Grafana application
resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  group             = "Infrastructure"
  protocol_provider = authentik_provider_oauth2.grafana.id
  meta_launch_url   = "https://grafana.golden.wales/login/generic_oauth"
  meta_icon         = "https://grafana.com/static/img/menu/grafana2.svg"
  open_in_new_tab   = true
}

# Output the client secret
output "grafana_client_id" {
  value = authentik_provider_oauth2.grafana.client_id
}

output "grafana_client_secret" {
  value     = random_password.grafana_client_secret.result
  sensitive = true
}

# Group for Grafana admins
resource "authentik_group" "grafana_admins" {
  name = "Grafana Admins"
}

# Property mapping to include groups in OAuth response
resource "authentik_property_mapping_provider_scope" "groups" {
  name       = "OAuth2 Groups"
  scope_name = "groups"
  expression = <<-EXPR
    return {
      "groups": [group.name for group in user.ak_groups.all()]
    }
  EXPR
}
