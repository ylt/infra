terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2024.12"
    }
  }
}

provider "authentik" {
  url   = "https://auth.golden.wales"
  token = var.authentik_token
}

variable "authentik_token" {
  description = "Authentik API token"
  type        = string
  sensitive   = true
}
