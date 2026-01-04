# Groups and policies for media apps (Jellyfin uses LDAP via module)

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

# Bind media-users policy to media apps
resource "authentik_policy_binding" "sonarr" {
  target = module.sonarr.authentik_application_uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}

resource "authentik_policy_binding" "radarr" {
  target = module.radarr.authentik_application_uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}

resource "authentik_policy_binding" "prowlarr" {
  target = module.prowlarr.authentik_application_uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}

resource "authentik_policy_binding" "bazarr" {
  target = module.bazarr.authentik_application_uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}

resource "authentik_policy_binding" "qbittorrent" {
  target = module.qbittorrent.authentik_application_uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}

resource "authentik_policy_binding" "jellyfin" {
  target = module.jellyfin.authentik_application_uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}

resource "authentik_policy_binding" "jellyseerr" {
  target = module.jellyseerr.authentik_application_uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}

# Service account for LDAP bind
resource "random_password" "jellyfin_ldap_bind" {
  count   = var.jellyfin_ldap_bind_password == null ? 1 : 0
  length  = 32
  special = false
}

locals {
  jellyfin_ldap_password = coalesce(var.jellyfin_ldap_bind_password, try(random_password.jellyfin_ldap_bind[0].result, null))
}

resource "authentik_user" "jellyfin_ldap_bind" {
  username = "jellyfin-ldap"
  name     = "Jellyfin LDAP Service Account"
  path     = "services"
  type     = "service_account"
  password = local.jellyfin_ldap_password
  groups   = [authentik_group.media_users.id]
}

# Output LDAP connection details for Jellyfin configuration
output "jellyfin_ldap" {
  value = {
    host          = "ak-outpost-ldap-outpost.authentik.svc.cluster.local"
    port          = 389
    base_dn       = module.jellyfin.ldap_base_dn
    bind_user     = "cn=${authentik_user.jellyfin_ldap_bind.username},ou=users,${module.jellyfin.ldap_base_dn}"
    bind_password = local.jellyfin_ldap_password
  }
  sensitive = true
}
