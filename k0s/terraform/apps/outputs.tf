# OAuth credentials for apps that need them configured externally
output "oauth_credentials" {
  description = "OAuth client credentials for apps using OAuth auth mode"
  value = {
    for app in local.all_apps : app.oauth_client_id => {
      client_id     = app.oauth_client_id
      client_secret = app.oauth_client_secret
    } if app.oauth_client_id != null
  }
  sensitive = true
}
