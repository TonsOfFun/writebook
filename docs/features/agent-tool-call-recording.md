# Agent Tool Call Recording

## Overview

This feature provides a mechanism for capturing and persisting tool call results in the `AgentContext`. When agents like `ResearchAssistantAgent` perform tool calls (web fetch, search, browser automation, etc.), the inputs, outputs, timing, and status of each tool execution are automatically recorded.

## Implementation Details

### New Files Created

1. **Migration**: `db/migrate/20251228123555_create_agent_tool_calls.rb`
   - Creates `agent_tool_calls` table with fields for tool name, arguments, result, status, timing, and position

2. **Model**: `app/models/agent_tool_call.rb`
   - ActiveRecord model for persisting tool call data
   - Methods: `start!`, `complete!`, `fail!`, `success?`, `failed?`, `in_progress?`
   - Scopes: `ordered`, `pending`, `executing`, `completed`, `failed`, `for_tool`, `successful`
   - Class methods: `total_duration_ms`, `statistics`

3. **Concern**: `app/agents/concerns/records_tool_calls.rb`
   - Automatically wraps tool methods to record their execution
   - Hooks into `has_tools` and `tool_description` to auto-wrap tools
   - Uses `prepend` pattern to intercept tool method calls

### Modified Files

1. **`app/models/agent_context.rb`**
   - Added `has_many :tool_calls` association
   - Added helper methods:
     - `record_tool_call_start(name:, arguments:, tool_call_id:)`
     - `record_tool_call_complete(tool_call, result:)`
     - `record_tool_call_failure(tool_call, error:)`
     - `tool_calls_for(name)` - get all calls for a specific tool
     - `tool_call_results` - get all completed results with metadata
     - `tool_results_for(name)` - get results for a specific tool
     - `tool_call_statistics` - get summary statistics

2. **`app/agents/application_agent.rb`**
   - Added `include RecordsToolCalls` to enable automatic tool call recording

## Database Schema

```ruby
create_table :agent_tool_calls do |t|
  t.references :agent_context, null: false, foreign_key: true
  t.string :tool_call_id       # UUID from LLM's tool_call request
  t.string :name, null: false  # Tool name (e.g., "navigate")
  t.json :arguments, default: {}
  t.json :result
  t.string :status, default: "pending"  # pending, executing, completed, failed
  t.text :error_message
  t.datetime :started_at
  t.datetime :completed_at
  t.integer :duration_ms
  t.integer :position, default: 0
  t.timestamps
end
```

## Usage Examples

### Accessing Tool Call Results from Context

```ruby
# After an agent has executed with tools
agent = ResearchAssistantAgent.new
agent.research(topic: "AI trends", contextable: document)

# Access the context
context = agent.context

# Get all tool calls
context.tool_calls.count  #=> 5

# Get tool calls for a specific tool
context.tool_calls_for(:navigate)  #=> [AgentToolCall, ...]

# Get all completed results with metadata
context.tool_call_results
#=> [
#     { name: "navigate", arguments: {url: "..."}, result: {...}, duration_ms: 150 },
#     { name: "extract_text", arguments: {...}, result: {...}, duration_ms: 200 }
#   ]

# Get just the results for a specific tool
context.tool_results_for(:navigate)
#=> [{success: true, current_url: "...", title: "..."}, ...]

# Get statistics
context.tool_call_statistics
#=> {
#     total: 5,
#     completed: 4,
#     failed: 1,
#     pending: 0,
#     executing: 0,
#     total_duration_ms: 850,
#     by_tool: {"navigate" => 2, "extract_text" => 2, "click" => 1}
#   }
```

### Querying Tool Calls

```ruby
# Find all failed tool calls
context.tool_calls.failed

# Find successful tool calls
context.tool_calls.successful

# Get total execution time
context.tool_calls.total_duration_ms

# Get tool calls in execution order
context.tool_calls.ordered
```

### Individual Tool Call Details

```ruby
tool_call = context.tool_calls.first

tool_call.name           #=> "navigate"
tool_call.parsed_arguments  #=> {url: "https://example.com"}
tool_call.parsed_result     #=> {success: true, title: "Example"}
tool_call.duration_ms    #=> 150
tool_call.success?       #=> true
tool_call.started_at     #=> 2024-12-28 12:35:00 UTC
tool_call.completed_at   #=> 2024-12-28 12:35:00 UTC
```

## Architecture

```
User Request
    ↓
Agent Action (e.g., ResearchAssistantAgent.research)
    ├→ create_context() → AgentContext created
    ├→ prompt(tools: tools)
    │
    └→ Tool Execution Loop (when finish_reason: "tool_calls")
        │
        └→ RecordsToolCalls intercepts each tool method call:
            ├→ record_tool_call_start() → AgentToolCall created (status: executing)
            ├→ Tool method executes
            ├→ record_tool_call_complete() → AgentToolCall updated (status: completed)
            └→ OR record_tool_call_failure() → AgentToolCall updated (status: failed)

AgentContext
├─ messages (conversation history)
├─ generations (LLM responses with token usage)
└─ tool_calls (individual tool executions)
   ├─ name, arguments, result
   ├─ status (pending → executing → completed/failed)
   └─ timing (started_at, completed_at, duration_ms)
```

## Benefits

1. **Audit Trail**: Complete history of all tool calls made during an agent session
2. **Debugging**: Examine tool inputs/outputs when something goes wrong
3. **Performance Analysis**: Track execution times to identify slow tools
4. **Rich Context**: Use tool results to build follow-up prompts or summaries
5. **Analytics**: Aggregate statistics across agent sessions

## Tests

Tests are located in `test/models/agent_context_test.rb`:
- `AgentToolCallTest` - tests for the model itself
- `AgentContextToolCallsTest` - tests for the context integration
