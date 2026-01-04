# Prowlarr indexer sync to *arr apps

# Sync indexers to Sonarr
resource "prowlarr_application_sonarr" "sonarr" {
  name            = "Sonarr"
  sync_level      = "fullSync"
  base_url        = "http://sonarr.media.svc.cluster.local:8989"
  prowlarr_url    = "http://prowlarr.media.svc.cluster.local:9696"
  api_key         = var.sonarr_api_key
  sync_categories = [5000, 5010, 5020, 5030, 5040, 5045, 5050]
}

# Sync indexers to Radarr
resource "prowlarr_application_radarr" "radarr" {
  name            = "Radarr"
  sync_level      = "fullSync"
  base_url        = "http://radarr.media.svc.cluster.local:7878"
  prowlarr_url    = "http://prowlarr.media.svc.cluster.local:9696"
  api_key         = var.radarr_api_key
  sync_categories = [2000, 2010, 2020, 2030, 2040, 2045, 2050, 2060]
}
