terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

provider "grafana" {
  url  = "https://grafana.golden.wales"
  auth = var.grafana_auth
}

variable "grafana_auth" {
  description = "Grafana API key or admin credentials (user:pass)"
  type        = string
  sensitive   = true
}
