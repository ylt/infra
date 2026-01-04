terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2024.12"
    }
    homarr = {
      source = "local/joe/homarr"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "authentik" {
  url   = "https://auth.golden.wales"
  token = var.authentik_token
}

provider "homarr" {
  url           = "https://homarr.golden.wales"
  api_key       = var.homarr_api_key
  session_token = var.homarr_session_token
}
