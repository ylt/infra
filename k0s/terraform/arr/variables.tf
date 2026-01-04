variable "sonarr_api_key" {
  type        = string
  sensitive   = true
  description = "Sonarr API key"
}

variable "radarr_api_key" {
  type        = string
  sensitive   = true
  description = "Radarr API key"
}

variable "prowlarr_api_key" {
  type        = string
  sensitive   = true
  description = "Prowlarr API key"
}

variable "jellyfin_api_key" {
  type        = string
  sensitive   = true
  description = "Jellyfin API key"
}
