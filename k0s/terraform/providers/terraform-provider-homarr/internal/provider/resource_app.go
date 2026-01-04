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
var _ resource.Resource = &AppResource{}
var _ resource.ResourceWithImportState = &AppResource{}

func NewAppResource() resource.Resource {
	return &AppResource{}
}

// AppResource defines the resource implementation.
type AppResource struct {
	client *HomarrClient
}

// AppResourceModel describes the resource data model.
type AppResourceModel struct {
	ID          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	IconURL     types.String `tfsdk:"icon_url"`
	URL         types.String `tfsdk:"url"`
	Description types.String `tfsdk:"description"`
	PingURL     types.String `tfsdk:"ping_url"`
}

func (r *AppResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_app"
}

func (r *AppResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Manages an app tile on the Homarr dashboard.",

		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "The unique identifier of the app.",
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.UseStateForUnknown(),
				},
			},
			"name": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "The display name of the app.",
			},
			"icon_url": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "The URL of the app icon.",
			},
			"url": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "The URL the app links to (href).",
			},
			"description": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "A description of the app.",
			},
			"ping_url": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "The URL to ping for health checks.",
			},
		},
	}
}

func (r *AppResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
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

// Helper to convert types.String to *string for API
func stringPtr(s types.String) *string {
	if s.IsNull() || s.IsUnknown() {
		empty := ""
		return &empty
	}
	val := s.ValueString()
	return &val
}

// Helper to convert *string from API to types.String
func stringValue(s *string) types.String {
	if s == nil || *s == "" {
		return types.StringNull()
	}
	return types.StringValue(*s)
}

func (r *AppResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var data AppResourceModel

	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	app := &App{
		Name:        data.Name.ValueString(),
		IconURL:     data.IconURL.ValueString(),
		Href:        stringPtr(data.URL),
		Description: stringPtr(data.Description),
		PingURL:     stringPtr(data.PingURL),
	}

	created, err := r.client.CreateApp(app)
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to create app: %s", err))
		return
	}

	data.ID = types.StringValue(created.ID)
	data.Name = types.StringValue(created.Name)
	data.IconURL = types.StringValue(created.IconURL)
	data.URL = stringValue(created.Href)
	data.Description = stringValue(created.Description)
	data.PingURL = stringValue(created.PingURL)

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *AppResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var data AppResourceModel

	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	app, err := r.client.GetApp(data.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to read app: %s", err))
		return
	}

	data.Name = types.StringValue(app.Name)
	data.IconURL = types.StringValue(app.IconURL)
	data.URL = stringValue(app.Href)
	data.Description = stringValue(app.Description)
	data.PingURL = stringValue(app.PingURL)

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *AppResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var data AppResourceModel

	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	app := &App{
		Name:        data.Name.ValueString(),
		IconURL:     data.IconURL.ValueString(),
		Href:        stringPtr(data.URL),
		Description: stringPtr(data.Description),
		PingURL:     stringPtr(data.PingURL),
	}

	updated, err := r.client.UpdateApp(data.ID.ValueString(), app)
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to update app: %s", err))
		return
	}

	data.Name = types.StringValue(updated.Name)
	data.IconURL = types.StringValue(updated.IconURL)
	data.URL = stringValue(updated.Href)
	data.Description = stringValue(updated.Description)
	data.PingURL = stringValue(updated.PingURL)

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *AppResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var data AppResourceModel

	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.client.DeleteApp(data.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to delete app: %s", err))
		return
	}
}

func (r *AppResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
	resp.Diagnostics.Append(resp.State.SetAttribute(ctx, path.Root("id"), req.ID)...)
}
