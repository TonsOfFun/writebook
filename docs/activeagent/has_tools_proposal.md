# HasTools Concern - Proposed ActiveAgent Framework Feature

## Summary

The `HasTools` concern provides a DSL for declarative tool definition in ActiveAgent agents, reducing boilerplate and following Rails conventions for tool schema management.

## Problem Statement

Currently, ActiveAgent requires developers to manually:
1. Define tool schemas as inline hashes or load them from JSON files
2. Write boilerplate code to load and parse tool schemas from view templates
3. Pass the tools array manually to `prompt(tools: [...])` on every call

This leads to repetitive code across agents:

```ruby
# Current approach - lots of boilerplate
class MyAgent < ApplicationAgent
  def my_action
    prompt(tools: load_tools, tool_choice: "auto")
  end

  private

  def load_tools
    tool_names = %w[tool1 tool2 tool3]
    tool_names.map { |name| load_tool_schema(name) }
  end

  def load_tool_schema(tool_name)
    json_content = render_to_string(
      template: "my_agent/tools/#{tool_name}",
      formats: [:json],
      layout: false
    )
    JSON.parse(json_content, symbolize_names: true)
  end
end
```

## Proposed Solution

A `HasTools` concern that provides:

### 1. Declarative Tool Registration

```ruby
class MyAgent < ApplicationAgent
  include HasTools

  # Explicit list - loads from views
  has_tools :navigate, :search, :analyze

  # Or auto-discover all tools in app/views/my_agent/tools/*.json.erb
  has_tools
end
```

### 2. Inline Tool DSL

```ruby
class MyAgent < ApplicationAgent
  include HasTools

  tool :get_weather do
    description "Get current weather for a location"
    parameter :location, type: :string, required: true, description: "City name"
    parameter :units, type: :string, enum: %w[celsius fahrenheit]
  end
end
```

### 3. Simple Usage in Actions

```ruby
def my_action
  prompt(tools: tools, tool_choice: "auto")  # tools method provided by concern
end
```

## Implementation

See: `app/agents/concerns/has_tools.rb`

### Key Features

- **Auto-discovery**: Scans `app/views/{agent_name}/tools/*.json.erb` for tool definitions
- **Explicit listing**: `has_tools :tool1, :tool2` loads only specified tools
- **Inline definition**: `tool :name do ... end` DSL for code-defined tools
- **Mixed approach**: Combine template-based and inline tools
- **Caching**: Tool schemas are cached per-instance with `reload_tools!` for development
- **Convention over configuration**: Follows Rails patterns for view lookup

### DSL Methods

| Method | Description |
|--------|-------------|
| `has_tools` | Enable auto-discovery of tools from templates |
| `has_tools :a, :b, :c` | Load specific tools from templates |
| `tool :name do...end` | Define tool inline with DSL |
| `tools` | Returns all tool schemas (instance method) |
| `reload_tools!` | Clear cache and reload schemas |

### ToolBuilder DSL

```ruby
tool :example do
  description "What this tool does"

  # Simple parameter
  parameter :query, type: :string, required: true

  # With description
  parameter :limit, type: :integer, description: "Max results", default: 10

  # Enum values
  parameter :format, type: :string, enum: %w[json xml csv]

  # Array type
  parameter :tags, type: :array, items: { type: :string }

  # Object type
  parameter :options, type: :object, properties: { ... }
end
```

## Example Usage

### Before (current pattern)

```ruby
class ResearchAssistantAgent < ApplicationAgent
  def research
    prompt(tools: load_tools, tool_choice: "auto")
  end

  private

  def load_tools
    tool_names = %w[navigate click fill_form extract_text]
    tool_names.map { |name| load_tool_schema(name) }
  end

  def load_tool_schema(tool_name)
    template_path = "tools/#{tool_name}"
    json_content = render_to_string(
      template: "research_assistant_agent/#{template_path}",
      formats: [:json],
      layout: false
    )
    JSON.parse(json_content, symbolize_names: true)
  rescue ActionView::MissingTemplate => e
    Rails.logger.error "Missing tool template: #{template_path}"
    raise e
  rescue JSON::ParserError => e
    Rails.logger.error "Invalid JSON in tool template: #{template_path}"
    raise e
  end
end
```

### After (with HasTools)

```ruby
class ResearchAssistantAgent < ApplicationAgent
  include HasTools

  has_tools :navigate, :click, :fill_form, :extract_text

  def research
    prompt(tools: tools, tool_choice: "auto")
  end
end
```

**Lines of code reduced**: ~25 lines of boilerplate per agent

## Integration with ActiveAgent

This concern could be integrated into ActiveAgent::Base as an opt-in feature:

```ruby
# In ActiveAgent::Base
include HasTools if defined?(HasTools)

# Or as a class method
class MyAgent < ApplicationAgent
  has_tools :navigate, :click  # Would work out of the box
end
```

## Documentation Updates Needed

If adopted, the following docs at https://docs.activeagents.ai should be updated:

1. **Actions > Tools** - Add section on declarative tool registration
2. **Framework > DSL** - Document the `tool` block syntax
3. **Getting Started** - Show simplified tool setup

## Testing Considerations

- Unit tests for ToolBuilder DSL
- Integration tests for template loading
- Edge cases: missing templates, invalid JSON, mixed definition modes

## Compatibility

- Works with all providers (OpenAI, Anthropic, Ollama, OpenRouter)
- Tool schema format matches existing ActiveAgent conventions
- Non-breaking addition - existing code continues to work
