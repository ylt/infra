package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/path"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringdefault"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

// Ensure provider defined types fully satisfy framework interfaces.
var _ resource.Resource = &SearchEngineResource{}
var _ resource.ResourceWithImportState = &SearchEngineResource{}

func NewSearchEngineResource() resource.Resource {
	return &SearchEngineResource{}
}

// SearchEngineResource defines the resource implementation.
type SearchEngineResource struct {
	client *HomarrClient
}

// SearchEngineResourceModel describes the resource data model.
type SearchEngineResourceModel struct {
	ID            types.String `tfsdk:"id"`
	Type          types.String `tfsdk:"type"`
	Name          types.String `tfsdk:"name"`
	Short         types.String `tfsdk:"short"`
	Description   types.String `tfsdk:"description"`
	IconURL       types.String `tfsdk:"icon_url"`
	URLTemplate   types.String `tfsdk:"url_template"`
	IntegrationID types.String `tfsdk:"integration_id"`
}

func (r *SearchEngineResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_search_engine"
}

func (r *SearchEngineResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Manages a search engine in Homarr. Requires session_token authentication.",

		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "The unique identifier of the search engine.",
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.UseStateForUnknown(),
				},
			},
			"type": schema.StringAttribute{
				Optional:            true,
				Computed:            true,
				Default:             stringdefault.StaticString("generic"),
				MarkdownDescription: "The type of search engine: 'generic' for URL-based or 'fromIntegration' to use an integration.",
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.RequiresReplace(),
				},
			},
			"name": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "The display name of the search engine.",
			},
			"short": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "The keyboard shortcut for this search engine (e.g., 'g' for Google).",
			},
			"description": schema.StringAttribute{
				Optional:            true,
				Computed:            true,
				Default:             stringdefault.StaticString(""),
				MarkdownDescription: "A description of the search engine.",
			},
			"icon_url": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "The URL to the search engine's icon. Required for 'generic' type.",
			},
			"url_template": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "The URL template with %s placeholder for the search query. Required for 'generic' type.",
			},
			"integration_id": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "The ID of an integration to use for searching. Required for 'fromIntegration' type.",
			},
		},
	}
}

func (r *SearchEngineResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
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

func (r *SearchEngineResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var data SearchEngineResourceModel

	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if r.client.SessionToken == "" {
		resp.Diagnostics.AddError("Missing Session Token", "Search engines require session_token authentication. Please configure session_token in the provider.")
		return
	}

	seType := data.Type.ValueString()
	if seType == "" {
		seType = "generic"
	}

	input := CreateSearchEngineInput{
		Type:        seType,
		Name:        data.Name.ValueString(),
		Short:       data.Short.ValueString(),
		Description: data.Description.ValueString(),
	}

	if seType == "generic" {
		input.IconURL = data.IconURL.ValueString()
		input.URLTemplate = data.URLTemplate.ValueString()
	} else if seType == "fromIntegration" {
		input.IntegrationID = data.IntegrationID.ValueString()
	}

	created, err := r.client.CreateSearchEngine(input)
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to create search engine: %s", err))
		return
	}

	data.ID = types.StringValue(created.ID)
	data.Type = types.StringValue(created.Type)
	data.Name = types.StringValue(created.Name)
	data.Short = types.StringValue(created.Short)
	data.Description = types.StringValue(created.Description)
	if created.IconURL != "" {
		data.IconURL = types.StringValue(created.IconURL)
	}
	if created.URLTemplate != "" {
		data.URLTemplate = types.StringValue(created.URLTemplate)
	}
	if created.IntegrationID != nil {
		data.IntegrationID = types.StringValue(*created.IntegrationID)
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *SearchEngineResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var data SearchEngineResourceModel

	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if r.client.SessionToken == "" {
		resp.Diagnostics.AddError("Missing Session Token", "Search engines require session_token authentication. Please configure session_token in the provider.")
		return
	}

	searchEngine, err := r.client.GetSearchEngineByID(data.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to read search engine: %s", err))
		return
	}

	data.Type = types.StringValue(searchEngine.Type)
	data.Name = types.StringValue(searchEngine.Name)
	data.Short = types.StringValue(searchEngine.Short)
	data.Description = types.StringValue(searchEngine.Description)
	if searchEngine.IconURL != "" {
		data.IconURL = types.StringValue(searchEngine.IconURL)
	}
	if searchEngine.URLTemplate != "" {
		data.URLTemplate = types.StringValue(searchEngine.URLTemplate)
	}
	if searchEngine.IntegrationID != nil {
		data.IntegrationID = types.StringValue(*searchEngine.IntegrationID)
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *SearchEngineResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var data SearchEngineResourceModel

	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if r.client.SessionToken == "" {
		resp.Diagnostics.AddError("Missing Session Token", "Search engines require session_token authentication. Please configure session_token in the provider.")
		return
	}

	seType := data.Type.ValueString()
	if seType == "" {
		seType = "generic"
	}

	input := UpdateSearchEngineInput{
		ID:          data.ID.ValueString(),
		Type:        seType,
		Name:        data.Name.ValueString(),
		Short:       data.Short.ValueString(),
		Description: data.Description.ValueString(),
	}

	if seType == "generic" {
		input.IconURL = data.IconURL.ValueString()
		input.URLTemplate = data.URLTemplate.ValueString()
	} else if seType == "fromIntegration" {
		input.IntegrationID = data.IntegrationID.ValueString()
	}

	err := r.client.UpdateSearchEngine(input)
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to update search engine: %s", err))
		return
	}

	// Refresh from API
	searchEngine, err := r.client.GetSearchEngineByID(data.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to read search engine after update: %s", err))
		return
	}

	data.Type = types.StringValue(searchEngine.Type)
	data.Name = types.StringValue(searchEngine.Name)
	data.Short = types.StringValue(searchEngine.Short)
	data.Description = types.StringValue(searchEngine.Description)
	if searchEngine.IconURL != "" {
		data.IconURL = types.StringValue(searchEngine.IconURL)
	}
	if searchEngine.URLTemplate != "" {
		data.URLTemplate = types.StringValue(searchEngine.URLTemplate)
	}
	if searchEngine.IntegrationID != nil {
		data.IntegrationID = types.StringValue(*searchEngine.IntegrationID)
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *SearchEngineResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var data SearchEngineResourceModel

	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if r.client.SessionToken == "" {
		resp.Diagnostics.AddError("Missing Session Token", "Search engines require session_token authentication. Please configure session_token in the provider.")
		return
	}

	err := r.client.DeleteSearchEngine(data.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to delete search engine: %s", err))
		return
	}
}

func (r *SearchEngineResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
	resp.Diagnostics.Append(resp.State.SetAttribute(ctx, path.Root("id"), req.ID)...)
}
