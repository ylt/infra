# Kubernetes Service Connection for managed outposts
resource "authentik_service_connection_kubernetes" "local" {
  name  = "Local Kubernetes"
  local = true
}

# Media users group - grants access to all media apps
resource "authentik_group" "media_users" {
  name = "media-users"
}

# Jellyfin admins - for admin rights within Jellyfin
resource "authentik_group" "jellyfin_admins" {
  name = "jellyfin-admins"
}

# Policy requiring media-users group membership
resource "authentik_policy_expression" "media_users_required" {
  name       = "media-users-required"
  expression = <<-EOT
    return ak_is_group_member(request.user, name="media-users")
  EOT
}

# Media apps that require media-users group
locals {
  media_apps = ["prowlarr", "sonarr", "radarr", "bazarr", "qbittorrent"]
}

# Bind media-users policy to media apps
resource "authentik_policy_binding" "media_apps" {
  for_each = toset(local.media_apps)

  target = authentik_application.apps[each.key].uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}

# Bind media-users policy to Jellyfin LDAP app
resource "authentik_policy_binding" "jellyfin_ldap" {
  target = authentik_application.jellyfin_ldap.uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}

# Service account for LDAP bind
resource "random_password" "jellyfin_ldap_bind" {
  length  = 32
  special = false
}

resource "authentik_user" "jellyfin_ldap_bind" {
  username = "jellyfin-ldap"
  name     = "Jellyfin LDAP Service Account"
  path     = "services"
  type     = "service_account"
  password = random_password.jellyfin_ldap_bind.result
  groups   = [authentik_group.media_users.id]
}

# Jellyfin LDAP provider
data "authentik_flow" "default-authentication-flow" {
  slug = "default-authentication-flow"
}

resource "authentik_provider_ldap" "jellyfin" {
  name         = "jellyfin-ldap"
  base_dn      = "dc=ldap,dc=golden,dc=wales"
  bind_flow    = data.authentik_flow.default-authentication-flow.id
  unbind_flow  = data.authentik_flow.default-invalidation-flow.id
  certificate  = data.authentik_certificate_key_pair.default.id
}

# Application for Jellyfin LDAP
resource "authentik_application" "jellyfin_ldap" {
  name              = "Jellyfin"
  slug              = "jellyfin-ldap"
  group             = "Media"
  protocol_provider = authentik_provider_ldap.jellyfin.id
  meta_launch_url   = "https://jellyfin.golden.wales"
  meta_icon         = "https://raw.githubusercontent.com/jellyfin/jellyfin-ux/master/branding/SVG/icon-transparent.svg"
  open_in_new_tab   = true
}

# LDAP Outpost
resource "authentik_outpost" "ldap" {
  name                = "LDAP Outpost"
  type                = "ldap"
  protocol_providers  = [authentik_provider_ldap.jellyfin.id]
  service_connection  = authentik_service_connection_kubernetes.local.id
  config = jsonencode({
    authentik_host          = "https://auth.golden.wales"
    authentik_host_insecure = false
    log_level               = "info"
    object_naming_template  = "ak-outpost-%(name)s"
    kubernetes_replicas     = 1
    kubernetes_namespace    = "authentik"
    kubernetes_service_type = "ClusterIP"
  })
}

# Output the LDAP connection details for Jellyfin
output "jellyfin_ldap_host" {
  value = "ak-outpost-ldap-outpost.authentik.svc.cluster.local"
}

output "jellyfin_ldap_port" {
  value = 389
}

output "jellyfin_ldap_base_dn" {
  value = "dc=ldap,dc=golden,dc=wales"
}

output "jellyfin_ldap_bind_user" {
  value = "cn=${authentik_user.jellyfin_ldap_bind.username},ou=users,dc=ldap,dc=golden,dc=wales"
}

output "jellyfin_ldap_bind_password" {
  value     = random_password.jellyfin_ldap_bind.result
  sensitive = true
}
