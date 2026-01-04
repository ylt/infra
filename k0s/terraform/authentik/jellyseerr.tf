# Jellyseerr application (launcher only - uses Jellyfin auth)
resource "authentik_application" "jellyseerr" {
  name            = "Jellyseerr"
  slug            = "jellyseerr"
  group           = "Media"
  meta_launch_url = "https://jellyseerr.golden.wales"
  meta_icon       = "https://raw.githubusercontent.com/Fallenbagel/jellyseerr/main/public/android-chrome-512x512.png"
  open_in_new_tab = true
}

# Bind media-users policy to Jellyseerr
resource "authentik_policy_binding" "jellyseerr" {
  target = authentik_application.jellyseerr.uuid
  policy = authentik_policy_expression.media_users_required.id
  order  = 0
}
