terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
    }
    homarr = {
      source = "local/joe/homarr"
    }
  }
}
