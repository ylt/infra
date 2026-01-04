# Forward auth provider for protected services
resource "authentik_provider_proxy" "forward_auth" {
  name                  = "forward-auth"
  mode                  = "forward_single"
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
  external_host         = "https://auth.golden.wales"
  access_token_validity = "hours=24"
}

# Application for forward auth
resource "authentik_application" "forward_auth" {
  name              = "Forward Auth"
  slug              = "forward-auth"
  protocol_provider = authentik_provider_proxy.forward_auth.id
  meta_launch_url   = "blank://blank"
}

# Embedded outpost - import with: terraform import authentik_outpost.embedded fffc0b44-a8dd-4356-beee-c2befbd148fc
resource "authentik_outpost" "embedded" {
  name = "authentik Embedded Outpost"
  type = "proxy"
  protocol_providers = concat(
    [authentik_provider_proxy.forward_auth.id],
    [for k, v in authentik_provider_proxy.apps : v.id]
  )
  config = jsonencode({
    authentik_host                 = "https://auth.golden.wales"
    authentik_host_insecure        = false
    authentik_host_browser         = ""
    log_level                      = "info"
    object_naming_template         = "ak-outpost-%(name)s"
    docker_network                 = null
    docker_map_ports               = true
    docker_labels                  = null
    container_image                = null
    kubernetes_replicas            = 1
    kubernetes_namespace           = "authentik"
    kubernetes_ingress_annotations = {}
    kubernetes_ingress_secret_name = ""
    kubernetes_service_type        = "ClusterIP"
    kubernetes_disabled_components = []
    kubernetes_json_patches        = null
    refresh_interval               = "minutes=5"
  })
}

# Individual app entries for each protected service
locals {
  protected_apps = {
    "node-red" = {
      name  = "Node-RED"
      url   = "https://node-red.golden.wales"
      icon  = "https://nodered.org/about/resources/media/node-red-icon-2.svg"
      group = "Home Automation"
    }
    "zigbee2mqtt" = {
      name  = "Zigbee2MQTT"
      url   = "https://zigbee.golden.wales"
      icon  = "https://www.zigbee2mqtt.io/logo.png"
      group = "Home Automation"
    }
    "govee2mqtt" = {
      name  = "Govee2MQTT"
      url   = "https://govee.golden.wales"
      icon  = ""
      group = "Home Automation"
    }
    "longhorn" = {
      name  = "Longhorn"
      url   = "https://longhorn.golden.wales"
      icon  = "https://longhorn.io/img/logos/longhorn-icon-color.png"
      group = "Infrastructure"
    }
    "traefik" = {
      name  = "Traefik Dashboard"
      url   = "https://traefik.golden.wales"
      icon  = "https://doc.traefik.io/traefik/assets/img/traefik.logo.png"
      group = "Infrastructure"
    }
    "hubble" = {
      name  = "Hubble"
      url   = "https://hubble.golden.wales"
      icon  = "https://cdn.jsdelivr.net/gh/cilium/cilium@main/Documentation/images/logo-solo.svg"
      group = "Infrastructure"
    }
    "kubeview" = {
      name  = "KubeView"
      url   = "https://kubeview.golden.wales"
      icon  = "https://kubeview.benco.io/public/img/icon.png"
      group = "Infrastructure"
    }
    "garage" = {
      name  = "Garage"
      url   = "https://garage.golden.wales"
      icon  = "https://garagehq.deuxfleurs.fr/images/garage-logo.svg"
      group = "Infrastructure"
    }
    "juicefs" = {
      name  = "JuiceFS"
      url   = "https://juicefs.golden.wales"
      icon  = "https://juicefs.com/static/favicon.ico"
      group = "Infrastructure"
    }
    "prowlarr" = {
      name  = "Prowlarr"
      url   = "https://prowlarr.golden.wales"
      icon  = "https://raw.githubusercontent.com/Prowlarr/Prowlarr/develop/Logo/128.png"
      group = "Media Admin"
    }
    "sonarr" = {
      name  = "Sonarr"
      url   = "https://sonarr.golden.wales"
      icon  = "https://raw.githubusercontent.com/Sonarr/Sonarr/develop/Logo/128.png"
      group = "Media Admin"
    }
    "radarr" = {
      name  = "Radarr"
      url   = "https://radarr.golden.wales"
      icon  = "https://raw.githubusercontent.com/Radarr/Radarr/develop/Logo/128.png"
      group = "Media Admin"
    }
    "bazarr" = {
      name  = "Bazarr"
      url   = "https://bazarr.golden.wales"
      icon  = "https://raw.githubusercontent.com/morpheus65535/bazarr/master/frontend/public/images/logo128.png"
      group = "Media Admin"
    }
    "qbittorrent" = {
      name  = "qBittorrent"
      url   = "https://qbit.golden.wales"
      icon  = "https://upload.wikimedia.org/wikipedia/commons/6/66/New_qBittorrent_Logo.svg"
      group = "Media Admin"
    }
  }
}

# Create proxy provider for each protected app
resource "authentik_provider_proxy" "apps" {
  for_each = local.protected_apps

  name               = each.key
  mode               = "forward_single"
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  external_host      = each.value.url
}

# Create application for each protected app
resource "authentik_application" "apps" {
  for_each = local.protected_apps

  name              = each.value.name
  slug              = each.key
  group             = each.value.group
  protocol_provider = authentik_provider_proxy.apps[each.key].id
  meta_launch_url   = each.value.url
  meta_icon         = each.value.icon != "" ? each.value.icon : null
  open_in_new_tab   = true
}
