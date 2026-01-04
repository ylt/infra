#!/bin/bash
# Migration script: k0s/terraform/authentik -> k0s/terraform/apps
#
# Generates imports.tf with import blocks for bulk import
# Usage:
#   cd k0s/terraform/apps
#   ./migrate.sh
#   terraform plan   # Review imports
#   terraform apply  # Execute imports

set -e

OLD_DIR="../authentik"
OUTPUT="imports.tf"

# Pull entire state once
STATE=$(cd "$OLD_DIR" && terraform state pull)

get_id_simple() {
  local type="$1"
  local name="$2"
  echo "$STATE" | jq -r --arg t "$type" --arg n "$name" '.resources[] | select(.type == $t and .name == $n) | .instances[0].attributes.id' 2>/dev/null
}

get_id_indexed() {
  local type="$1"
  local name="$2"
  local key="$3"
  echo "$STATE" | jq -r --arg t "$type" --arg n "$name" --arg k "$key" '.resources[] | select(.type == $t and .name == $n) | .instances[] | select(.index_key == $k) | .attributes.id' 2>/dev/null
}

cat > "$OUTPUT" << 'EOF'
# Generated import blocks - run terraform apply to import
# Delete this file after successful import

EOF

echo "Generating $OUTPUT..."

# Forward auth apps
for app in sonarr radarr prowlarr bazarr qbittorrent longhorn traefik node-red zigbee2mqtt govee2mqtt garage hubble juicefs kubeview; do
  proxy_id=$(get_id_indexed "authentik_provider_proxy" "apps" "$app")
  app_id=$(get_id_indexed "authentik_application" "apps" "$app")

  if [ -n "$proxy_id" ] && [ "$proxy_id" != "null" ]; then
    mod_name=$(echo "$app" | tr '-' '_')
    cat >> "$OUTPUT" << EOF
import {
  to = module.${mod_name}.authentik_provider_proxy.this[0]
  id = "$proxy_id"
}
import {
  to = module.${mod_name}.authentik_application.this[0]
  id = "$app_id"
}
EOF
  fi
done

# OAuth apps
for app in grafana homeassistant homarr; do
  provider_id=$(get_id_simple "authentik_provider_oauth2" "$app")
  app_id=$(get_id_simple "authentik_application" "$app")

  if [ -n "$provider_id" ] && [ "$provider_id" != "null" ]; then
    cat >> "$OUTPUT" << EOF
import {
  to = module.${app}.authentik_provider_oauth2.this[0]
  id = "$provider_id"
}
import {
  to = module.${app}.authentik_application.this[0]
  id = "$app_id"
}
EOF
  fi
done

# Zot
zot_provider_id=$(get_id_simple "authentik_provider_oauth2" "zot")
zot_app_id=$(get_id_simple "authentik_application" "zot_oidc")
if [ -n "$zot_provider_id" ] && [ "$zot_provider_id" != "null" ]; then
  cat >> "$OUTPUT" << EOF
import {
  to = module.zot.authentik_provider_oauth2.this[0]
  id = "$zot_provider_id"
}
import {
  to = module.zot.authentik_application.this[0]
  id = "$zot_app_id"
}
EOF
fi

# LDAP (jellyfin)
jellyfin_ldap_id=$(get_id_simple "authentik_provider_ldap" "jellyfin")
jellyfin_app_id=$(get_id_simple "authentik_application" "jellyfin_ldap")
if [ -n "$jellyfin_ldap_id" ] && [ "$jellyfin_ldap_id" != "null" ]; then
  cat >> "$OUTPUT" << EOF
import {
  to = module.jellyfin.authentik_provider_ldap.this[0]
  id = "$jellyfin_ldap_id"
}
import {
  to = module.jellyfin.authentik_application.this[0]
  id = "$jellyfin_app_id"
}
EOF
fi

# Jellyseerr
jellyseerr_app_id=$(get_id_simple "authentik_application" "jellyseerr")
if [ -n "$jellyseerr_app_id" ] && [ "$jellyseerr_app_id" != "null" ]; then
  cat >> "$OUTPUT" << EOF
import {
  to = module.jellyseerr.authentik_application.this[0]
  id = "$jellyseerr_app_id"
}
EOF
fi

# Outposts
cat >> "$OUTPUT" << EOF
import {
  to = authentik_provider_proxy.forward_auth
  id = "$(get_id_simple authentik_provider_proxy forward_auth)"
}
import {
  to = authentik_application.forward_auth
  id = "$(get_id_simple authentik_application forward_auth)"
}
import {
  to = authentik_outpost.embedded
  id = "$(get_id_simple authentik_outpost embedded)"
}
import {
  to = authentik_outpost.ldap
  id = "$(get_id_simple authentik_outpost ldap)"
}
import {
  to = authentik_service_connection_kubernetes.local
  id = "$(get_id_simple authentik_service_connection_kubernetes local)"
}
EOF

# Groups and policies
cat >> "$OUTPUT" << EOF
import {
  to = authentik_group.media_users
  id = "$(get_id_simple authentik_group media_users)"
}
import {
  to = authentik_group.jellyfin_admins
  id = "$(get_id_simple authentik_group jellyfin_admins)"
}
import {
  to = authentik_policy_expression.media_users_required
  id = "$(get_id_simple authentik_policy_expression media_users_required)"
}
import {
  to = authentik_user.jellyfin_ldap_bind
  id = "$(get_id_simple authentik_user jellyfin_ldap_bind)"
}
EOF

# Policy bindings
for app in sonarr radarr prowlarr bazarr qbittorrent; do
  binding_id=$(get_id_indexed "authentik_policy_binding" "media_apps" "$app")
  if [ -n "$binding_id" ] && [ "$binding_id" != "null" ]; then
    cat >> "$OUTPUT" << EOF
import {
  to = authentik_policy_binding.${app}
  id = "$binding_id"
}
EOF
  fi
done

jellyfin_binding_id=$(get_id_simple "authentik_policy_binding" "jellyfin_ldap")
jellyseerr_binding_id=$(get_id_simple "authentik_policy_binding" "jellyseerr")

if [ -n "$jellyfin_binding_id" ] && [ "$jellyfin_binding_id" != "null" ]; then
  cat >> "$OUTPUT" << EOF
import {
  to = authentik_policy_binding.jellyfin
  id = "$jellyfin_binding_id"
}
EOF
fi

if [ -n "$jellyseerr_binding_id" ] && [ "$jellyseerr_binding_id" != "null" ]; then
  cat >> "$OUTPUT" << EOF
import {
  to = authentik_policy_binding.jellyseerr
  id = "$jellyseerr_binding_id"
}
EOF
fi

echo "Generated $(grep -c '^import {' "$OUTPUT") import blocks in $OUTPUT"
echo ""
echo "Next steps:"
echo "  terraform plan   # Review"
echo "  terraform apply  # Import all at once"
echo "  rm $OUTPUT       # Clean up after success"
