# Forward auth provider (for the embedded outpost)
resource "authentik_provider_proxy" "forward_auth" {
  name                  = "forward-auth"
  mode                  = "forward_single"
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
  external_host         = "https://auth.golden.wales"
  access_token_validity = "hours=24"
}

resource "authentik_application" "forward_auth" {
  name              = "Forward Auth"
  slug              = "forward-auth"
  protocol_provider = authentik_provider_proxy.forward_auth.id
  meta_launch_url   = "blank://blank"
}

# Collect provider IDs from all apps
locals {
  proxy_provider_ids = compact([for app in local.all_apps : app.proxy_provider_id])
  ldap_provider_ids  = compact([for app in local.all_apps : app.ldap_provider_id])
}

# Embedded outpost with all proxy providers
resource "authentik_outpost" "embedded" {
  name = "authentik Embedded Outpost"
  type = "proxy"
  protocol_providers = concat(
    [authentik_provider_proxy.forward_auth.id],
    local.proxy_provider_ids
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

# Kubernetes service connection for managed outposts
resource "authentik_service_connection_kubernetes" "local" {
  name  = "Local Kubernetes"
  local = true
}

# LDAP outpost
resource "authentik_outpost" "ldap" {
  name               = "LDAP Outpost"
  type               = "ldap"
  protocol_providers = local.ldap_provider_ids
  service_connection = authentik_service_connection_kubernetes.local.id
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
