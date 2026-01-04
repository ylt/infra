package provider

import (
	"context"
	"os"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

// Ensure HomarrProvider satisfies various provider interfaces.
var _ provider.Provider = &HomarrProvider{}

// HomarrProvider defines the provider implementation.
type HomarrProvider struct {
	version string
}

// HomarrProviderModel describes the provider data model.
type HomarrProviderModel struct {
	URL          types.String `tfsdk:"url"`
	APIKey       types.String `tfsdk:"api_key"`
	SessionToken types.String `tfsdk:"session_token"`
}

func (p *HomarrProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "homarr"
	resp.Version = p.version
}

func (p *HomarrProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "The Homarr provider allows you to manage your Homarr dashboard configuration.",
		Attributes: map[string]schema.Attribute{
			"url": schema.StringAttribute{
				MarkdownDescription: "The URL of your Homarr instance (e.g., https://homarr.example.com). Can also be set via HOMARR_URL environment variable.",
				Optional:            true,
			},
			"api_key": schema.StringAttribute{
				MarkdownDescription: "The API key for REST API authentication. Can also be set via HOMARR_API_KEY environment variable.",
				Optional:            true,
				Sensitive:           true,
			},
			"session_token": schema.StringAttribute{
				MarkdownDescription: "The session token for tRPC authentication (authjs.session-token cookie value). Required for groups, settings, integrations, and boards. Can also be set via HOMARR_SESSION_TOKEN environment variable.",
				Optional:            true,
				Sensitive:           true,
			},
		},
	}
}

func (p *HomarrProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	var config HomarrProviderModel

	resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)

	if resp.Diagnostics.HasError() {
		return
	}

	// Check environment variables for defaults
	url := os.Getenv("HOMARR_URL")
	apiKey := os.Getenv("HOMARR_API_KEY")
	sessionToken := os.Getenv("HOMARR_SESSION_TOKEN")

	// Override with config values if provided
	if !config.URL.IsNull() {
		url = config.URL.ValueString()
	}
	if !config.APIKey.IsNull() {
		apiKey = config.APIKey.ValueString()
	}
	if !config.SessionToken.IsNull() {
		sessionToken = config.SessionToken.ValueString()
	}

	// Validate required configuration
	if url == "" {
		resp.Diagnostics.AddError(
			"Missing Homarr URL",
			"The provider requires a Homarr URL. Set it in the provider configuration or via the HOMARR_URL environment variable.",
		)
	}
	if apiKey == "" && sessionToken == "" {
		resp.Diagnostics.AddError(
			"Missing Authentication",
			"The provider requires either an API key or session token. Set api_key or session_token in the provider configuration, or via HOMARR_API_KEY or HOMARR_SESSION_TOKEN environment variables.",
		)
	}

	if resp.Diagnostics.HasError() {
		return
	}

	// Create the API client
	client := NewHomarrClient(url, apiKey, sessionToken)
	resp.DataSourceData = client
	resp.ResourceData = client
}

func (p *HomarrProvider) Resources(ctx context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewAppResource,
		NewGroupResource,
		NewIntegrationResource,
		NewSearchEngineResource,
	}
}

func (p *HomarrProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{}
}

func New(version string) func() provider.Provider {
	return func() provider.Provider {
		return &HomarrProvider{
			version: version,
		}
	}
}
