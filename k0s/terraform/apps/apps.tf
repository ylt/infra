# =============================================================================
# Media Apps
# =============================================================================

module "sonarr" {
  source = "./modules/app"

  name         = "Sonarr"
  slug         = "sonarr"
  external_url = "https://sonarr.golden.wales"
  internal_url = "http://sonarr.media.svc.cluster.local:8989"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sonarr.svg"
  group        = "Media Admin"
  description  = "TV Shows"

  create_homarr_integration = true
  integration_kind          = "sonarr"
  api_key                   = var.sonarr_api_key

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "radarr" {
  source = "./modules/app"

  name         = "Radarr"
  slug         = "radarr"
  external_url = "https://radarr.golden.wales"
  internal_url = "http://radarr.media.svc.cluster.local:7878"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg"
  group        = "Media Admin"
  description  = "Movies"

  create_homarr_integration = true
  integration_kind          = "radarr"
  api_key                   = var.radarr_api_key

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "prowlarr" {
  source = "./modules/app"

  name         = "Prowlarr"
  slug         = "prowlarr"
  external_url = "https://prowlarr.golden.wales"
  internal_url = "http://prowlarr.media.svc.cluster.local:9696"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg"
  group        = "Media Admin"
  description  = "Indexer Manager"

  create_homarr_integration = true
  integration_kind          = "prowlarr"
  api_key                   = var.prowlarr_api_key

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "jellyfin" {
  source = "./modules/app"

  name         = "Jellyfin"
  slug         = "jellyfin"
  external_url = "https://jellyfin.golden.wales"
  internal_url = "http://jellyfin.media.svc.cluster.local:8096"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyfin.svg"
  group        = "Media"
  description  = "Media Server"

  auth_mode    = "ldap"
  ldap_base_dn = "dc=ldap,dc=golden,dc=wales"

  create_homarr_integration = true
  integration_kind          = "jellyfin"
  api_key                   = var.jellyfin_api_key

  authentik_authentication_flow_id = local.authentik_defaults.authentication_flow_id
  authentik_invalidation_flow_id   = local.authentik_defaults.invalidation_flow_id
  authentik_signing_key_id         = local.authentik_defaults.signing_key_id
}

module "jellyseerr" {
  source = "./modules/app"

  name         = "Jellyseerr"
  slug         = "jellyseerr"
  external_url = "https://jellyseerr.golden.wales"
  internal_url = "http://jellyseerr.media.svc.cluster.local:5055"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyseerr.svg"
  group        = "Media"
  description  = "Media Requests"

  # Launcher only - uses Jellyfin auth
  auth_mode = "none"

  create_homarr_integration   = true
  integration_kind            = "jellyseerr"
  api_key                     = var.jellyseerr_api_key
  create_homarr_search_engine = true
  search_short                = "jelly"
  search_url_template         = "https://jellyseerr.golden.wales/search?query=%s"
}

module "bazarr" {
  source = "./modules/app"

  name         = "Bazarr"
  slug         = "bazarr"
  external_url = "https://bazarr.golden.wales"
  internal_url = "http://bazarr.media.svc.cluster.local:6767"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bazarr.svg"
  group        = "Media Admin"
  description  = "Subtitles"

  # No Homarr integration - bazarr not in supported kinds

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "qbittorrent" {
  source = "./modules/app"

  name         = "qBittorrent"
  slug         = "qbittorrent"
  external_url = "https://qbit.golden.wales"
  internal_url = "http://qbittorrent.media.svc.cluster.local:8080"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/qbittorrent.svg"
  group        = "Media Admin"
  description  = "Torrent Client"

  create_homarr_integration = true
  integration_kind          = "qBittorrent"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

# =============================================================================
# Infrastructure Apps
# =============================================================================

module "grafana" {
  source = "./modules/app"

  name         = "Grafana"
  slug         = "grafana"
  external_url = "https://grafana.golden.wales"
  launch_url   = "https://grafana.golden.wales/login/generic_oauth"
  internal_url = "http://grafana.monitoring.svc.cluster.local:3000"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/grafana.svg"
  group        = "Infrastructure"
  description  = "Dashboards"

  auth_mode           = "oauth"
  oauth_redirect_path = "/login/generic_oauth"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
  authentik_signing_key_id        = local.authentik_defaults.signing_key_id
  authentik_property_mapping_ids  = local.authentik_defaults.property_mapping_ids
}

module "longhorn" {
  source = "./modules/app"

  name         = "Longhorn"
  slug         = "longhorn"
  external_url = "https://longhorn.golden.wales"
  internal_url = "http://longhorn-frontend.longhorn-system.svc.cluster.local:80"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/longhorn.svg"
  group        = "Infrastructure"
  description  = "Storage Management"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "traefik" {
  source = "./modules/app"

  name         = "Traefik"
  slug         = "traefik"
  external_url = "https://traefik.golden.wales"
  internal_url = "http://traefik.traefik.svc.cluster.local:9000"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/traefik.svg"
  group        = "Infrastructure"
  description  = "Ingress Controller"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "hubble" {
  source = "./modules/app"

  name         = "Hubble"
  slug         = "hubble"
  external_url = "https://hubble.golden.wales"
  internal_url = "http://hubble-ui.kube-system.svc.cluster.local:80"
  icon_url     = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/cilium-hubble.svg"
  group        = "Infrastructure"
  description  = "Network Observability"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "kubeview" {
  source = "./modules/app"

  name         = "KubeView"
  slug         = "kubeview"
  external_url = "https://kubeview.golden.wales"
  internal_url = "http://kubeview.kube-system.svc.cluster.local:80"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/kubernetes-dashboard.svg"
  group        = "Infrastructure"
  description  = "Cluster Visualization"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "garage" {
  source = "./modules/app"

  name         = "Garage"
  slug         = "garage"
  external_url = "https://garage.golden.wales"
  internal_url = "http://garage.garage.svc.cluster.local:3900"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/garage.svg"
  group        = "Infrastructure"
  description  = "S3-Compatible Storage"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "juicefs" {
  source = "./modules/app"

  name         = "JuiceFS"
  slug         = "juicefs"
  external_url = "https://juicefs.golden.wales"
  internal_url = "http://juicefs-console.juicefs.svc.cluster.local:80"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/juicefs.svg"
  group        = "Infrastructure"
  description  = "Distributed Filesystem"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "zot" {
  source = "./modules/app"

  name         = "Zot Registry"
  slug         = "zot"
  external_url = "https://zot.golden.wales"
  launch_url   = "https://zot.golden.wales/zot/auth/login?callback_ui=https://zot.golden.wales/home&provider=oidc"
  internal_url = "http://zot.zot.svc.cluster.local:5000"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/zot-registry.svg"
  group        = "Infrastructure"
  description  = "Container Registry"

  auth_mode           = "oauth"
  oauth_redirect_path = "/zot/auth/callback/oidc"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
  authentik_signing_key_id        = local.authentik_defaults.signing_key_id
  authentik_property_mapping_ids  = local.authentik_defaults.property_mapping_ids
}

module "homarr" {
  source = "./modules/app"

  name         = "Homarr"
  slug         = "homarr"
  external_url = "https://homarr.golden.wales"
  launch_url   = "https://homarr.golden.wales/api/auth/signin/oidc"
  internal_url = "http://homarr.homarr.svc.cluster.local:7575"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/homarr.svg"
  group        = "Infrastructure"
  description  = "Dashboard"

  auth_mode           = "oauth"
  oauth_redirect_path = "/api/auth/callback/oidc"

  # Don't create homarr tile for homarr itself
  create_homarr_tile = false

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
  authentik_signing_key_id        = local.authentik_defaults.signing_key_id
  authentik_property_mapping_ids  = local.authentik_defaults.property_mapping_ids
}

# =============================================================================
# Home Automation
# =============================================================================

module "homeassistant" {
  source = "./modules/app"

  name         = "Home Assistant"
  slug         = "homeassistant"
  external_url = "https://home.golden.wales"
  launch_url   = "https://home.golden.wales/auth/oidc/redirect"
  internal_url = "http://homeassistant.homeassistant.svc.cluster.local:8123"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/home-assistant.svg"
  group        = "Home Automation"
  description  = "Smart Home"

  auth_mode           = "oauth"
  oauth_redirect_path = "/auth/external/callback"

  create_homarr_integration = true
  integration_kind          = "homeAssistant"
  api_key                   = var.homeassistant_api_key

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
  authentik_signing_key_id        = local.authentik_defaults.signing_key_id
  authentik_property_mapping_ids  = local.authentik_defaults.property_mapping_ids
}

module "node_red" {
  source = "./modules/app"

  name         = "Node-RED"
  slug         = "node-red"
  external_url = "https://node-red.golden.wales"
  internal_url = "http://node-red.node-red.svc.cluster.local:1880"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/node-red.svg"
  group        = "Home Automation"
  description  = "Flow Automation"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "zigbee2mqtt" {
  source = "./modules/app"

  name         = "Zigbee2MQTT"
  slug         = "zigbee2mqtt"
  external_url = "https://zigbee.golden.wales"
  internal_url = "http://zigbee2mqtt.zigbee2mqtt.svc.cluster.local:80"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/zigbee2mqtt.svg"
  group        = "Home Automation"
  description  = "Zigbee Bridge"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "govee2mqtt" {
  source = "./modules/app"

  name         = "Govee2MQTT"
  slug         = "govee2mqtt"
  external_url = "https://govee.golden.wales"
  internal_url = "http://govee2mqtt.govee2mqtt.svc.cluster.local:8056"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/govee.svg"
  group        = "Home Automation"
  description  = "Govee Bridge"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

module "openhab" {
  source = "./modules/app"

  name         = "openHAB"
  slug         = "openhab"
  external_url = "https://openhab.golden.wales"
  internal_url = "http://openhab.openhab.svc.cluster.local:8080"
  icon_url     = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/openhab.svg"
  group        = "Home Automation"
  description  = "Home Automation"

  authentik_authorization_flow_id = local.authentik_defaults.authorization_flow_id
  authentik_invalidation_flow_id  = local.authentik_defaults.invalidation_flow_id
}

# =============================================================================
# Collect all apps for outpost and outputs
# =============================================================================

locals {
  all_apps = [
    # Media
    module.sonarr,
    module.radarr,
    module.prowlarr,
    module.jellyfin,
    module.jellyseerr,
    module.bazarr,
    module.qbittorrent,
    # Infrastructure
    module.grafana,
    module.longhorn,
    module.traefik,
    module.hubble,
    module.kubeview,
    module.garage,
    module.juicefs,
    module.zot,
    module.homarr,
    # Home Automation
    module.homeassistant,
    module.node_red,
    module.zigbee2mqtt,
    module.govee2mqtt,
    module.openhab,
  ]
}
