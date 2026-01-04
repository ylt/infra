package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/path"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

// Ensure provider defined types fully satisfy framework interfaces.
var _ resource.Resource = &IntegrationResource{}
var _ resource.ResourceWithImportState = &IntegrationResource{}

func NewIntegrationResource() resource.Resource {
	return &IntegrationResource{}
}

// IntegrationResource defines the resource implementation.
type IntegrationResource struct {
	client *HomarrClient
}

// IntegrationResourceModel describes the resource data model.
type IntegrationResourceModel struct {
	ID     types.String `tfsdk:"id"`
	Name   types.String `tfsdk:"name"`
	Kind   types.String `tfsdk:"kind"`
	URL    types.String `tfsdk:"url"`
	APIKey types.String `tfsdk:"api_key"`
}

func (r *IntegrationResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_integration"
}

func (r *IntegrationResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Manages an integration in Homarr. Requires session_token authentication.",

		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "The unique identifier of the integration.",
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.UseStateForUnknown(),
				},
			},
			"name": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "The display name of the integration.",
			},
			"kind": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "The type of integration (e.g., sonarr, radarr, jellyfin, plex, homeAssistant, piHole, adGuardHome, etc.).",
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.RequiresReplace(),
				},
			},
			"url": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "The URL of the integration service.",
			},
			"api_key": schema.StringAttribute{
				Optional:            true,
				Sensitive:           true,
				MarkdownDescription: "The API key for the integration (if required by the service).",
			},
		},
	}
}

func (r *IntegrationResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	client, ok := req.ProviderData.(*HomarrClient)
	if !ok {
		resp.Diagnostics.AddError(
			"Unexpected Resource Configure Type",
			fmt.Sprintf("Expected *HomarrClient, got: %T", req.ProviderData),
		)
		return
	}

	r.client = client
}

func (r *IntegrationResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var data IntegrationResourceModel

	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if r.client.SessionToken == "" {
		resp.Diagnostics.AddError("Missing Session Token", "Integrations require session_token authentication. Please configure session_token in the provider.")
		return
	}

	secrets := make([]IntegrationSecret, 0)
	if !data.APIKey.IsNull() && data.APIKey.ValueString() != "" {
		secrets = append(secrets, IntegrationSecret{
			Kind:  "apiKey",
			Value: data.APIKey.ValueString(),
		})
	}

	input := CreateIntegrationInput{
		Name:                        data.Name.ValueString(),
		Kind:                        data.Kind.ValueString(),
		URL:                         data.URL.ValueString(),
		Secrets:                     secrets,
		AttemptSearchEngineCreation: false,
	}

	created, err := r.client.CreateIntegration(input)
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to create integration: %s", err))
		return
	}

	data.ID = types.StringValue(created.ID)
	data.Name = types.StringValue(created.Name)
	data.Kind = types.StringValue(created.Kind)
	data.URL = types.StringValue(created.URL)

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *IntegrationResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var data IntegrationResourceModel

	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if r.client.SessionToken == "" {
		resp.Diagnostics.AddError("Missing Session Token", "Integrations require session_token authentication. Please configure session_token in the provider.")
		return
	}

	integration, err := r.client.GetIntegrationByID(data.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to read integration: %s", err))
		return
	}

	data.Name = types.StringValue(integration.Name)
	data.Kind = types.StringValue(integration.Kind)
	data.URL = types.StringValue(integration.URL)
	// Note: API key is write-only, we don't read it back

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *IntegrationResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var data IntegrationResourceModel

	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if r.client.SessionToken == "" {
		resp.Diagnostics.AddError("Missing Session Token", "Integrations require session_token authentication. Please configure session_token in the provider.")
		return
	}

	secrets := make([]IntegrationSecret, 0)
	if !data.APIKey.IsNull() && data.APIKey.ValueString() != "" {
		secrets = append(secrets, IntegrationSecret{
			Kind:  "apiKey",
			Value: data.APIKey.ValueString(),
		})
	}

	input := UpdateIntegrationInput{
		ID:      data.ID.ValueString(),
		Name:    data.Name.ValueString(),
		URL:     data.URL.ValueString(),
		Secrets: secrets,
	}

	err := r.client.UpdateIntegration(input)
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to update integration: %s", err))
		return
	}

	// Refresh from API
	integration, err := r.client.GetIntegrationByID(data.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to read integration after update: %s", err))
		return
	}

	data.Name = types.StringValue(integration.Name)
	data.URL = types.StringValue(integration.URL)

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *IntegrationResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var data IntegrationResourceModel

	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if r.client.SessionToken == "" {
		resp.Diagnostics.AddError("Missing Session Token", "Integrations require session_token authentication. Please configure session_token in the provider.")
		return
	}

	err := r.client.DeleteIntegration(data.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to delete integration: %s", err))
		return
	}
}

func (r *IntegrationResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
	resp.Diagnostics.Append(resp.State.SetAttribute(ctx, path.Root("id"), req.ID)...)
}
