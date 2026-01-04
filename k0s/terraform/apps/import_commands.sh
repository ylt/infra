#!/bin/bash
# Generated import commands - review before running
set -e

# Forward auth apps
terraform import 'module.sonarr.authentik_provider_proxy.this[0]' '13'
terraform import 'module.sonarr.authentik_application.this[0]' 'sonarr'
terraform import 'module.radarr.authentik_provider_proxy.this[0]' '14'
terraform import 'module.radarr.authentik_application.this[0]' 'radarr'
terraform import 'module.prowlarr.authentik_provider_proxy.this[0]' '12'
terraform import 'module.prowlarr.authentik_application.this[0]' 'prowlarr'
terraform import 'module.bazarr.authentik_provider_proxy.this[0]' '15'
terraform import 'module.bazarr.authentik_application.this[0]' 'bazarr'
terraform import 'module.qbittorrent.authentik_provider_proxy.this[0]' '9'
terraform import 'module.qbittorrent.authentik_application.this[0]' 'qbittorrent'
terraform import 'module.longhorn.authentik_provider_proxy.this[0]' '16'
terraform import 'module.longhorn.authentik_application.this[0]' 'longhorn'
terraform import 'module.traefik.authentik_provider_proxy.this[0]' '7'
terraform import 'module.traefik.authentik_application.this[0]' 'traefik'
terraform import 'module.node_red.authentik_provider_proxy.this[0]' '17'
terraform import 'module.node_red.authentik_application.this[0]' 'node-red'
terraform import 'module.zigbee2mqtt.authentik_provider_proxy.this[0]' '11'
terraform import 'module.zigbee2mqtt.authentik_application.this[0]' 'zigbee2mqtt'
terraform import 'module.govee2mqtt.authentik_provider_proxy.this[0]' '8'
terraform import 'module.govee2mqtt.authentik_application.this[0]' 'govee2mqtt'
terraform import 'module.garage.authentik_provider_proxy.this[0]' '20'
terraform import 'module.garage.authentik_application.this[0]' 'garage'
terraform import 'module.hubble.authentik_provider_proxy.this[0]' '10'
terraform import 'module.hubble.authentik_application.this[0]' 'hubble'
terraform import 'module.juicefs.authentik_provider_proxy.this[0]' '19'
terraform import 'module.juicefs.authentik_application.this[0]' 'juicefs'
terraform import 'module.kubeview.authentik_provider_proxy.this[0]' '6'
terraform import 'module.kubeview.authentik_application.this[0]' 'kubeview'

# OAuth apps
terraform import 'module.grafana.authentik_provider_oauth2.this[0]' '18'
terraform import 'module.grafana.authentik_application.this[0]' 'grafana'
terraform import 'module.homeassistant.authentik_provider_oauth2.this[0]' '3'
terraform import 'module.homeassistant.authentik_application.this[0]' 'home-assistant'
terraform import 'module.homarr.authentik_provider_oauth2.this[0]' '21'
terraform import 'module.homarr.authentik_application.this[0]' 'homarr'
terraform import 'module.zot.authentik_provider_oauth2.this[0]' '5'
terraform import 'module.zot.authentik_application.this[0]' 'zot-oidc'

# LDAP (jellyfin)
terraform import 'module.jellyfin.authentik_provider_ldap.this[0]' '1'
terraform import 'module.jellyfin.authentik_application.this[0]' 'jellyfin-ldap'
terraform import 'module.jellyseerr.authentik_application.this[0]' 'jellyseerr'

# Outposts and shared resources
terraform import 'authentik_provider_proxy.forward_auth' '2'
terraform import 'authentik_application.forward_auth' 'forward-auth'
terraform import 'authentik_outpost.embedded' 'b2485b25-90ca-4cc5-8e52-3b4db1de0955'
terraform import 'authentik_outpost.ldap[0]' '00a9c478-dd93-4e0c-8fb0-5239068e0070'
terraform import 'authentik_service_connection_kubernetes.local' '9ebc1a78-6d82-4ad8-b133-11b049b0752b'

# Groups and policies
terraform import 'authentik_group.media_users' 'fe1af870-f435-4400-a2c8-808cfdef2aa1'
terraform import 'authentik_group.jellyfin_admins' '5b2914c5-ce7d-4b61-804d-141b654f072b'
terraform import 'authentik_policy_expression.media_users_required' 'b92fcc43-4326-40cf-a17e-b84e2df4be43'
terraform import 'authentik_user.jellyfin_ldap_bind' '8'

# Add to terraform.tfvars to preserve LDAP bind password:
# jellyfin_ldap_bind_password = "PfWZxXKT6jHp7qSlu1UO6BTmECLT2kDF"

# Policy bindings
terraform import 'authentik_policy_binding.sonarr' 'be311751-17a1-41ce-abef-eceb112c9315'
terraform import 'authentik_policy_binding.radarr' '93ac7cfa-d55f-4539-af98-45af0ef9f654'
terraform import 'authentik_policy_binding.prowlarr' 'ce60ca8d-c54f-4529-ac6b-cb254356ea22'
terraform import 'authentik_policy_binding.bazarr' '2cddb754-7d7c-4fe1-9baa-9dde51bbd737'
terraform import 'authentik_policy_binding.qbittorrent' 'd7bc0ecf-a645-4875-bccc-223868d40972'
terraform import 'authentik_policy_binding.jellyfin' 'fc49d58f-5b15-471f-90ef-a14621c96b30'
terraform import 'authentik_policy_binding.jellyseerr' '5a38db00-4f05-49ad-b960-db2522c9d9e5'

echo '=== Import complete ==='
echo 'Next steps:'
echo '1. Run: terraform plan'
echo '2. Fix any drift (regenerated secrets will show as changes)'
echo '3. Apply if needed: terraform apply'
echo '4. Archive old state: mv ../authentik/terraform.tfstate* ../authentik/backup/'
