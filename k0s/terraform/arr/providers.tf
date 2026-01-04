terraform {
  required_providers {
    sonarr = {
      source  = "devopsarr/sonarr"
      version = "~> 3.0"
    }
    radarr = {
      source  = "devopsarr/radarr"
      version = "~> 2.0"
    }
    prowlarr = {
      source  = "devopsarr/prowlarr"
      version = "~> 2.0"
    }
  }
}

provider "sonarr" {
  url     = "http://localhost:8989"
  api_key = var.sonarr_api_key
}

provider "radarr" {
  url     = "http://localhost:7878"
  api_key = var.radarr_api_key
}

provider "prowlarr" {
  url     = "http://localhost:9696"
  api_key = var.prowlarr_api_key
}
