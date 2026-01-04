# qBittorrent download client configuration for all *arr apps

locals {
  qbit_host = "qbittorrent.media.svc.cluster.local"
  qbit_port = 8080
}

# Register with Sonarr
resource "sonarr_download_client_qbittorrent" "qbit" {
  name                       = "qBittorrent"
  host                       = local.qbit_host
  port                       = local.qbit_port
  tv_category                = "tv-sonarr"
  enable                     = true
  priority                   = 1
  remove_completed_downloads = true
  remove_failed_downloads    = true
}

# Register with Radarr
resource "radarr_download_client_qbittorrent" "qbit" {
  name                       = "qBittorrent"
  host                       = local.qbit_host
  port                       = local.qbit_port
  movie_category             = "movies-radarr"
  enable                     = true
  priority                   = 1
  remove_completed_downloads = true
  remove_failed_downloads    = true
}

# Register with Prowlarr
resource "prowlarr_download_client_qbittorrent" "qbit" {
  name     = "qBittorrent"
  host     = local.qbit_host
  port     = local.qbit_port
  category = "prowlarr"
  enable   = true
  priority = 1
}
