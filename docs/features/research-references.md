# Research References Feature

## Overview

This feature provides a mechanism for capturing, displaying, and managing research references discovered during AI research sessions. When users use the Research tool while writing a page, all URLs visited and content extracted are automatically captured and made available for review, citation, and linking.

## Key Features

1. **Automatic Reference Extraction**: References are captured in real-time as the ResearchAssistantAgent navigates the web
2. **OG Metadata Preview**: Reference cards display Open Graph metadata (title, description, image) when available
3. **Copy Actions**: Users can copy markdown links `[Title](URL)` or plain URLs to clipboard
4. **References Panel**: A slide-out panel in the page editor shows all research sources
5. **Badge Indicator**: The toolbar shows a count badge when references exist

## Implementation Details

### Database Schema

**`agent_references` table:**
```ruby
create_table :agent_references do |t|
  t.references :agent_context, null: false
  t.references :agent_tool_call  # Optional link to source tool call

  t.string :url, null: false
  t.string :title
  t.text :description

  # Open Graph metadata
  t.string :og_title
  t.text :og_description
  t.string :og_image
  t.string :og_site_name
  t.string :og_type
  t.string :favicon_url

  t.string :domain
  t.json :metadata, default: {}
  t.text :extracted_content

  t.string :status  # pending, fetching, complete, failed
  t.text :error_message
  t.integer :position

  t.timestamps
end
```

### Models

**`AgentReference`** (`app/models/agent_reference.rb`):
- Belongs to `AgentContext`
- Optionally linked to the `AgentToolCall` that discovered it
- Methods: `display_title`, `display_description`, `to_markdown_link`, `as_card`
- Scopes: `ordered`, `complete`, `pending`, `with_metadata`

**`AgentContext`** additions:
- `has_many :references`
- `extract_references!` - extracts references from tool calls
- `reference_cards` - returns formatted cards for UI

**`Contextable` concern** additions:
- `agent_references` - all references through contexts
- `research_references` - references from research agents
- `research_reference_cards` - formatted cards for UI
- `has_research_references?` - boolean check

### Agent Integration

**`ResearchAssistantAgent`**:
- Includes `extracts_references` declaration
- References are automatically extracted from:
  - `navigate` tool calls (URL + title)
  - `extract_main_content` tool calls (content summary)
  - `extract_links` tool calls (discovered links)

**`RecordsToolCalls` concern** (`app/agents/concerns/records_tool_calls.rb`):
- `extracts_references` class method enables automatic extraction
- `extract_reference_from_tool_call` handles per-tool extraction logic

### Views

**`app/views/references/_panel.html.erb`**:
- Slide-out panel with Turbo Frame for lazy loading

**`app/views/references/_list.html.erb`**:
- References list with header and count

**`app/views/references/_card.html.erb`**:
- Individual reference card with:
  - OG image preview
  - Favicon and domain
  - Title and description
  - Extracted content expandable section
  - Copy markdown link button
  - Copy URL button
  - Open in new tab link

### Stimulus Controllers

**`references_controller.js`**:
- `copyMarkdownLink` - copies `[Title](URL)` format
- `copyUrl` - copies plain URL
- `insertLink` - inserts markdown link at cursor (future feature)
- `showCopiedFeedback` - visual feedback for copy actions

**`references_panel_controller.js`**:
- `toggle`, `open`, `close` - panel visibility
- Handles Escape key to close
- Listens for global `references-panel:toggle` event

### Routes

```ruby
resources :books do
  resources :leaves, only: [] do
    resources :references, only: [:index]
  end
end
```

## Usage

### In the Page Editor

1. Click the Research tool button in the toolbar
2. The AI researches the topic and visits web pages
3. References are automatically captured during research
4. After research completes, click the link icon in the toolbar to view sources
5. Copy markdown links to cite sources in your content

### Accessing References Programmatically

```ruby
# Get all research references for a page
page.research_references

# Get reference cards for UI display
page.research_reference_cards

# Check if page has references
page.has_research_references?

# Get references from a specific context
context.references.complete
context.reference_cards

# Extract references from tool calls (usually automatic)
context.extract_references!
```

## Files Created/Modified

### New Files
- `db/migrate/20251228141706_create_agent_references.rb`
- `app/models/agent_reference.rb`
- `app/controllers/references_controller.rb`
- `app/views/references/_panel.html.erb`
- `app/views/references/_list.html.erb`
- `app/views/references/_card.html.erb`
- `app/javascript/controllers/references_controller.js`
- `app/javascript/controllers/references_panel_controller.js`
- `app/assets/stylesheets/references.css`

### Modified Files
- `app/models/agent_context.rb` - added references association and methods
- `app/models/concerns/solid_agent/contextable.rb` - added reference helpers
- `app/agents/concerns/records_tool_calls.rb` - added `extracts_references` support
- `app/agents/research_assistant_agent.rb` - enabled reference extraction
- `app/views/pages/edit.html.erb` - added references toggle button and panel
- `config/routes.rb` - added references routes
- `test/models/agent_context_test.rb` - added reference tests

## Future Enhancements

1. **Citation Formatting**: Support for APA, MLA, Chicago citation formats
2. **Reference Organization**: Group by session, domain, or topic
3. **Metadata Fetching**: Background job to fetch OG metadata for pending references
4. **Reference Search**: Filter and search through references
5. **Export**: Export references as bibliography
6. **Insert at Cursor**: Insert markdown link directly at editor cursor position
