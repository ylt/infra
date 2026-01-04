# Examples

This directory contains example Terraform configurations for the Homarr provider.

## provider/

Complete working example with:
- Provider configuration with dual authentication
- Integration resources (Sonarr, Radarr, Prowlarr, Jellyfin)

### Running the Example

1. Build the provider:
   ```bash
   cd ..
   go build -o terraform-provider-homarr
   ```

2. Configure `~/.terraformrc` with dev overrides (see main README)

3. Set credentials:
   ```bash
   export TF_VAR_homarr_api_key="your-api-key"
   export TF_VAR_homarr_session_token="your-session-token"
   ```

4. Apply:
   ```bash
   cd provider
   terraform apply
   ```
