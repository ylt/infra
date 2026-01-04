package provider

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// HomarrClient is the API client for Homarr
type HomarrClient struct {
	BaseURL      string
	APIKey       string
	SessionToken string
	HTTPClient   *http.Client
}

// NewHomarrClient creates a new Homarr API client
func NewHomarrClient(baseURL, apiKey, sessionToken string) *HomarrClient {
	return &HomarrClient{
		BaseURL:      baseURL,
		APIKey:       apiKey,
		SessionToken: sessionToken,
		HTTPClient:   &http.Client{},
	}
}

// doRequest performs an HTTP request with API key authentication (REST API)
func (c *HomarrClient) doRequest(method, path string, body interface{}) ([]byte, error) {
	var reqBody io.Reader
	if body != nil {
		jsonBody, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request body: %w", err)
		}
		reqBody = bytes.NewBuffer(jsonBody)
	}

	req, err := http.NewRequest(method, c.BaseURL+path, reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("ApiKey", c.APIKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("API error (status %d): %s", resp.StatusCode, string(respBody))
	}

	return respBody, nil
}

// TRPCResponse wraps the tRPC response format
type TRPCResponse struct {
	Result struct {
		Data struct {
			JSON json.RawMessage `json:"json"`
		} `json:"data"`
	} `json:"result"`
	Error *struct {
		JSON struct {
			Message string `json:"message"`
			Code    int    `json:"code"`
		} `json:"json"`
	} `json:"error"`
}

// doTRPCQuery performs a tRPC GET query with session token authentication (no input)
func (c *HomarrClient) doTRPCQuery(procedure string, input interface{}) (json.RawMessage, error) {
	url := c.BaseURL + "/api/trpc/" + procedure

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Cookie", "authjs.session-token="+c.SessionToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	var trpcResp TRPCResponse
	if err := json.Unmarshal(respBody, &trpcResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal tRPC response: %w", err)
	}

	if trpcResp.Error != nil {
		return nil, fmt.Errorf("tRPC error: %s", trpcResp.Error.JSON.Message)
	}

	return trpcResp.Result.Data.JSON, nil
}

// doTRPCQueryWithInput performs a tRPC GET query with input parameter
func (c *HomarrClient) doTRPCQueryWithInput(procedure string, input interface{}) (json.RawMessage, error) {
	// tRPC queries with input need {"json": ...} wrapper in URL param
	wrapped := TRPCInput{JSON: input}
	inputJSON, err := json.Marshal(wrapped)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal input: %w", err)
	}

	url := c.BaseURL + "/api/trpc/" + procedure + "?input=" + string(inputJSON)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Cookie", "authjs.session-token="+c.SessionToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	var trpcResp TRPCResponse
	if err := json.Unmarshal(respBody, &trpcResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal tRPC response: %w", err)
	}

	if trpcResp.Error != nil {
		return nil, fmt.Errorf("tRPC error: %s", trpcResp.Error.JSON.Message)
	}

	return trpcResp.Result.Data.JSON, nil
}

// TRPCInput wraps input for tRPC mutations
type TRPCInput struct {
	JSON interface{} `json:"json"`
}

// doTRPCMutation performs a tRPC POST mutation with session token authentication
func (c *HomarrClient) doTRPCMutation(procedure string, input interface{}) (json.RawMessage, error) {
	var reqBody io.Reader
	if input != nil {
		// tRPC expects input wrapped in {"json": ...}
		wrapped := TRPCInput{JSON: input}
		jsonBody, err := json.Marshal(wrapped)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal input: %w", err)
		}
		reqBody = bytes.NewBuffer(jsonBody)
	}

	req, err := http.NewRequest("POST", c.BaseURL+"/api/trpc/"+procedure, reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Cookie", "authjs.session-token="+c.SessionToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	var trpcResp TRPCResponse
	if err := json.Unmarshal(respBody, &trpcResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal tRPC response: %w", err)
	}

	if trpcResp.Error != nil {
		return nil, fmt.Errorf("tRPC error: %s", trpcResp.Error.JSON.Message)
	}

	return trpcResp.Result.Data.JSON, nil
}

// =============================================================================
// App (REST API)
// =============================================================================

// App represents a Homarr app
type App struct {
	ID          string  `json:"id,omitempty"`
	Name        string  `json:"name"`
	IconURL     string  `json:"iconUrl"`
	Href        *string `json:"href"`
	Description *string `json:"description"`
	PingURL     *string `json:"pingUrl"`
}

// GetApps retrieves all apps
func (c *HomarrClient) GetApps() ([]App, error) {
	resp, err := c.doRequest("GET", "/api/apps", nil)
	if err != nil {
		return nil, err
	}

	var apps []App
	if err := json.Unmarshal(resp, &apps); err != nil {
		return nil, fmt.Errorf("failed to unmarshal apps: %w", err)
	}

	return apps, nil
}

// GetApp retrieves a single app by ID
func (c *HomarrClient) GetApp(id string) (*App, error) {
	resp, err := c.doRequest("GET", "/api/apps/"+id, nil)
	if err != nil {
		return nil, err
	}

	var app App
	if err := json.Unmarshal(resp, &app); err != nil {
		return nil, fmt.Errorf("failed to unmarshal app: %w", err)
	}

	return &app, nil
}

// CreateApp creates a new app
func (c *HomarrClient) CreateApp(app *App) (*App, error) {
	resp, err := c.doRequest("POST", "/api/apps", app)
	if err != nil {
		return nil, err
	}

	var created App
	if err := json.Unmarshal(resp, &created); err != nil {
		return nil, fmt.Errorf("failed to unmarshal created app: %w", err)
	}

	return &created, nil
}

// UpdateApp updates an existing app
func (c *HomarrClient) UpdateApp(id string, app *App) (*App, error) {
	_, err := c.doRequest("PATCH", "/api/apps/"+id, app)
	if err != nil {
		return nil, err
	}

	// PATCH returns empty body, so refetch the app
	return c.GetApp(id)
}

// DeleteApp deletes an app
func (c *HomarrClient) DeleteApp(id string) error {
	_, err := c.doRequest("DELETE", "/api/apps/"+id, nil)
	return err
}

// =============================================================================
// Group (tRPC)
// =============================================================================

// Group represents a Homarr group
type Group struct {
	ID       string        `json:"id"`
	Name     string        `json:"name"`
	Position int           `json:"position"`
	Members  []GroupMember `json:"members,omitempty"`
}

// GroupMember represents a member in a group
type GroupMember struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

// GetGroups retrieves all groups via tRPC
func (c *HomarrClient) GetGroups() ([]Group, error) {
	resp, err := c.doTRPCQuery("group.getAll", nil)
	if err != nil {
		return nil, err
	}

	var groups []Group
	if err := json.Unmarshal(resp, &groups); err != nil {
		return nil, fmt.Errorf("failed to unmarshal groups: %w", err)
	}

	return groups, nil
}

// GetGroup retrieves a single group by ID
func (c *HomarrClient) GetGroup(id string) (*Group, error) {
	groups, err := c.GetGroups()
	if err != nil {
		return nil, err
	}

	for _, g := range groups {
		if g.ID == id {
			return &g, nil
		}
	}

	return nil, fmt.Errorf("group not found: %s", id)
}

// CreateGroupInput represents the input for creating a group
type CreateGroupInput struct {
	Name string `json:"name"`
}

// CreateGroup creates a new group via tRPC
func (c *HomarrClient) CreateGroup(name string) (*Group, error) {
	input := CreateGroupInput{Name: name}
	resp, err := c.doTRPCMutation("group.createGroup", input)
	if err != nil {
		return nil, err
	}

	// Response is just the ID string
	var groupID string
	if err := json.Unmarshal(resp, &groupID); err != nil {
		return nil, fmt.Errorf("failed to unmarshal created group ID: %w", err)
	}

	// Fetch the full group
	return c.GetGroup(groupID)
}

// SaveGroupInput represents the input for updating a group
type SaveGroupInput struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// UpdateGroup updates an existing group via tRPC
func (c *HomarrClient) UpdateGroup(id, name string) (*Group, error) {
	input := SaveGroupInput{ID: id, Name: name}
	_, err := c.doTRPCMutation("group.updateGroup", input)
	if err != nil {
		return nil, err
	}

	return c.GetGroup(id)
}

// DeleteGroupInput represents the input for deleting a group
type DeleteGroupInput struct {
	ID string `json:"id"`
}

// DeleteGroup deletes a group via tRPC
func (c *HomarrClient) DeleteGroup(id string) error {
	input := DeleteGroupInput{ID: id}
	_, err := c.doTRPCMutation("group.deleteGroup", input)
	return err
}

// =============================================================================
// Server Settings (tRPC)
// =============================================================================

// ServerSettings represents all Homarr server settings
type ServerSettings struct {
	Analytics           AnalyticsSettings           `json:"analytics"`
	CrawlingAndIndexing CrawlingAndIndexingSettings `json:"crawlingAndIndexing"`
	Board               BoardSettings               `json:"board"`
	Appearance          AppearanceSettings          `json:"appearance"`
	Culture             CultureSettings             `json:"culture"`
	Search              SearchSettings              `json:"search"`
}

type AnalyticsSettings struct {
	EnableGeneral         bool `json:"enableGeneral"`
	EnableWidgetData      bool `json:"enableWidgetData"`
	EnableIntegrationData bool `json:"enableIntegrationData"`
	EnableUserData        bool `json:"enableUserData"`
}

type CrawlingAndIndexingSettings struct {
	NoIndex              bool `json:"noIndex"`
	NoFollow             bool `json:"noFollow"`
	NoTranslate          bool `json:"noTranslate"`
	NoSiteLinksSearchBox bool `json:"noSiteLinksSearchBox"`
}

type BoardSettings struct {
	HomeBoardID           *string `json:"homeBoardId"`
	MobileHomeBoardID     *string `json:"mobileHomeBoardId"`
	EnableStatusByDefault bool    `json:"enableStatusByDefault"`
	ForceDisableStatus    bool    `json:"forceDisableStatus"`
}

type AppearanceSettings struct {
	DefaultColorScheme string `json:"defaultColorScheme"`
}

type CultureSettings struct {
	DefaultLocale string `json:"defaultLocale"`
}

type SearchSettings struct {
	DefaultSearchEngineID string `json:"defaultSearchEngineId"`
}

// GetServerSettings retrieves all server settings via tRPC
func (c *HomarrClient) GetServerSettings() (*ServerSettings, error) {
	resp, err := c.doTRPCQuery("serverSettings.getAll", nil)
	if err != nil {
		return nil, err
	}

	var settings ServerSettings
	if err := json.Unmarshal(resp, &settings); err != nil {
		return nil, fmt.Errorf("failed to unmarshal server settings: %w", err)
	}

	return &settings, nil
}

// SaveServerSettings saves server settings via tRPC
func (c *HomarrClient) SaveServerSettings(settings *ServerSettings) error {
	_, err := c.doTRPCMutation("serverSettings.saveSettings", settings)
	return err
}

// =============================================================================
// Integration (tRPC)
// =============================================================================

// Integration represents a Homarr integration
type Integration struct {
	ID      string              `json:"id"`
	Name    string              `json:"name"`
	Kind    string              `json:"kind"`
	URL     string              `json:"url"`
	Secrets []IntegrationSecret `json:"secrets,omitempty"`
}

// IntegrationSecret represents a secret for an integration
type IntegrationSecret struct {
	Kind  string `json:"kind"`
	Value string `json:"value,omitempty"`
}

// CreateIntegrationInput represents the input for creating an integration
type CreateIntegrationInput struct {
	Name                        string              `json:"name"`
	Kind                        string              `json:"kind"`
	URL                         string              `json:"url"`
	Secrets                     []IntegrationSecret `json:"secrets"`
	AttemptSearchEngineCreation bool                `json:"attemptSearchEngineCreation"`
}

// UpdateIntegrationInput represents the input for updating an integration
type UpdateIntegrationInput struct {
	ID      string              `json:"id"`
	Name    string              `json:"name"`
	URL     string              `json:"url"`
	Secrets []IntegrationSecret `json:"secrets"`
	AppID   *string             `json:"appId"`
}

// GetIntegrations retrieves all integrations via tRPC
func (c *HomarrClient) GetIntegrations() ([]Integration, error) {
	resp, err := c.doTRPCQuery("integration.all", nil)
	if err != nil {
		return nil, err
	}

	var integrations []Integration
	if err := json.Unmarshal(resp, &integrations); err != nil {
		return nil, fmt.Errorf("failed to unmarshal integrations: %w", err)
	}

	return integrations, nil
}

// GetIntegrationByID retrieves a single integration by ID via tRPC query
func (c *HomarrClient) GetIntegrationByID(id string) (*Integration, error) {
	input := map[string]string{"id": id}
	resp, err := c.doTRPCQueryWithInput("integration.byId", input)
	if err != nil {
		return nil, err
	}

	var integration Integration
	if err := json.Unmarshal(resp, &integration); err != nil {
		return nil, fmt.Errorf("failed to unmarshal integration: %w", err)
	}

	return &integration, nil
}

// IntegrationErrorResponse represents an error returned in the response data
type IntegrationErrorResponse struct {
	Error *struct {
		Type    string `json:"type"`
		Name    string `json:"name"`
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

// CreateIntegration creates a new integration via tRPC
func (c *HomarrClient) CreateIntegration(input CreateIntegrationInput) (*Integration, error) {
	resp, err := c.doTRPCMutation("integration.create", input)
	if err != nil {
		return nil, err
	}

	// Check if the response contains an error (connectivity issues, etc.)
	if resp != nil && len(resp) > 0 && string(resp) != "null" {
		var errResp IntegrationErrorResponse
		if err := json.Unmarshal(resp, &errResp); err == nil && errResp.Error != nil {
			return nil, fmt.Errorf("integration error: %s", errResp.Error.Message)
		}
	}

	// The create response doesn't return the full object, so we need to find it
	integrations, err := c.GetIntegrations()
	if err != nil {
		return nil, err
	}

	// Find the newly created integration by name and kind
	for _, i := range integrations {
		if i.Name == input.Name && i.Kind == input.Kind {
			return &i, nil
		}
	}

	return nil, fmt.Errorf("created integration not found")
}

// UpdateIntegration updates an existing integration via tRPC
func (c *HomarrClient) UpdateIntegration(input UpdateIntegrationInput) error {
	_, err := c.doTRPCMutation("integration.update", input)
	return err
}

// DeleteIntegration deletes an integration via tRPC
func (c *HomarrClient) DeleteIntegration(id string) error {
	input := map[string]string{"id": id}
	_, err := c.doTRPCMutation("integration.delete", input)
	return err
}

// =============================================================================
// Board (tRPC)
// =============================================================================

// Board represents a Homarr board
type Board struct {
	ID           string  `json:"id"`
	Name         string  `json:"name"`
	LogoImageURL *string `json:"logoImageUrl"`
	IsPublic     bool    `json:"isPublic"`
	IsHome       bool    `json:"isHome"`
	IsMobileHome bool    `json:"isMobileHome"`
}

// GetBoards retrieves all boards via tRPC
func (c *HomarrClient) GetBoards() ([]Board, error) {
	resp, err := c.doTRPCQuery("board.getAllBoards", nil)
	if err != nil {
		return nil, err
	}

	var boards []Board
	if err := json.Unmarshal(resp, &boards); err != nil {
		return nil, fmt.Errorf("failed to unmarshal boards: %w", err)
	}

	return boards, nil
}

// GetBoard retrieves a single board by ID
func (c *HomarrClient) GetBoard(id string) (*Board, error) {
	boards, err := c.GetBoards()
	if err != nil {
		return nil, err
	}

	for _, b := range boards {
		if b.ID == id {
			return &b, nil
		}
	}

	return nil, fmt.Errorf("board not found: %s", id)
}

// =============================================================================
// Search Engine (tRPC)
// =============================================================================

// SearchEngine represents a Homarr search engine
type SearchEngine struct {
	ID            string  `json:"id"`
	Name          string  `json:"name"`
	Short         string  `json:"short"`
	Description   string  `json:"description"`
	IconURL       string  `json:"iconUrl"`
	URLTemplate   string  `json:"urlTemplate"`
	Type          string  `json:"type"`
	IntegrationID *string `json:"integrationId"`
}

// SearchEnginePaginatedResponse represents the paginated response
type SearchEnginePaginatedResponse struct {
	Items      []SearchEngine `json:"items"`
	TotalCount int            `json:"totalCount"`
}

// CreateSearchEngineInput represents the input for creating a search engine
type CreateSearchEngineInput struct {
	Type          string `json:"type"`
	Name          string `json:"name"`
	Short         string `json:"short"`
	Description   string `json:"description,omitempty"`
	IconURL       string `json:"iconUrl,omitempty"`
	URLTemplate   string `json:"urlTemplate,omitempty"`
	IntegrationID string `json:"integrationId,omitempty"`
}

// UpdateSearchEngineInput represents the input for updating a search engine
type UpdateSearchEngineInput struct {
	ID            string `json:"id"`
	Type          string `json:"type"`
	Name          string `json:"name"`
	Short         string `json:"short"`
	Description   string `json:"description,omitempty"`
	IconURL       string `json:"iconUrl,omitempty"`
	URLTemplate   string `json:"urlTemplate,omitempty"`
	IntegrationID string `json:"integrationId,omitempty"`
}

// GetSearchEngines retrieves all search engines via tRPC
func (c *HomarrClient) GetSearchEngines() ([]SearchEngine, error) {
	input := map[string]int{"limit": 100, "offset": 0}
	resp, err := c.doTRPCQueryWithInput("searchEngine.getPaginated", input)
	if err != nil {
		return nil, err
	}

	var result SearchEnginePaginatedResponse
	if err := json.Unmarshal(resp, &result); err != nil {
		return nil, fmt.Errorf("failed to unmarshal search engines: %w", err)
	}

	return result.Items, nil
}

// GetSearchEngineByID retrieves a single search engine by ID via tRPC query
func (c *HomarrClient) GetSearchEngineByID(id string) (*SearchEngine, error) {
	input := map[string]string{"id": id}
	resp, err := c.doTRPCQueryWithInput("searchEngine.byId", input)
	if err != nil {
		return nil, err
	}

	var searchEngine SearchEngine
	if err := json.Unmarshal(resp, &searchEngine); err != nil {
		return nil, fmt.Errorf("failed to unmarshal search engine: %w", err)
	}

	return &searchEngine, nil
}

// CreateSearchEngine creates a new search engine via tRPC
func (c *HomarrClient) CreateSearchEngine(input CreateSearchEngineInput) (*SearchEngine, error) {
	_, err := c.doTRPCMutation("searchEngine.create", input)
	if err != nil {
		return nil, err
	}

	// The create response doesn't return the full object, so we need to find it
	searchEngines, err := c.GetSearchEngines()
	if err != nil {
		return nil, err
	}

	// Find the newly created search engine by name and short
	for _, se := range searchEngines {
		if se.Name == input.Name && se.Short == input.Short {
			return &se, nil
		}
	}

	return nil, fmt.Errorf("created search engine not found")
}

// UpdateSearchEngine updates an existing search engine via tRPC
func (c *HomarrClient) UpdateSearchEngine(input UpdateSearchEngineInput) error {
	_, err := c.doTRPCMutation("searchEngine.update", input)
	return err
}

// DeleteSearchEngine deletes a search engine via tRPC
func (c *HomarrClient) DeleteSearchEngine(id string) error {
	input := map[string]string{"id": id}
	_, err := c.doTRPCMutation("searchEngine.delete", input)
	return err
}
