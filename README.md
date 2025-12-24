# Writebook (AI-Enhanced Fork)

A fork of [Writebook](https://github.com/basecamp/writebook) with integrated AI writing assistance powered by [ActiveAgent](https://github.com/activeagents/activeagent) and [SolidAgent](https://github.com/activeagents/solid_agent).

## What's Different in This Fork

This fork extends the original Writebook with a complete AI agent framework that provides:

- **Writing Assistant** - Improve, grammar check, summarize, expand, and brainstorm content
- **Research Assistant** - Autonomous web research with browser automation
- **File Analyzer** - PDF and image analysis with OCR-style text extraction
- **Real-time Streaming** - Live AI responses via ActionCable
- **Context Persistence** - Full audit trail of AI interactions stored in the database

## AI Agent Architecture

### Core Dependencies

```ruby
# Gemfile
gem "activeagent", "~> 1.0.1"   # Agent framework (like ActionMailer for AI)
gem "solid_agent", "~> 0.1.1"   # Database persistence & tool DSL
```

### Agent Structure

```
app/
├── agents/
│   ├── application_agent.rb         # Base agent with shared concerns
│   ├── writing_assistant_agent.rb   # Writing improvement features
│   ├── research_assistant_agent.rb  # Web research with browser tools
│   └── file_analyzer_agent.rb       # PDF/image analysis
├── models/
│   ├── agent_context.rb             # Conversation/session storage
│   ├── agent_message.rb             # Individual messages
│   └── agent_generation.rb          # AI response metadata & tokens
└── views/
    ├── writing_assistant_agent/     # Prompt templates
    ├── research_assistant_agent/    # Includes tools/*.json.erb
    └── file_analyzer_agent/
```

### SolidAgent Concerns

All agents inherit from `ApplicationAgent` which includes three SolidAgent concerns:

```ruby
class ApplicationAgent < ActiveAgent::Base
  include SolidAgent::HasContext          # Database-backed conversation history
  include SolidAgent::HasTools            # Declarative tool schema DSL
  include SolidAgent::StreamsToolUpdates  # Real-time tool status broadcasting
end
```

#### HasContext

Provides automatic persistence of prompts and AI responses:

```ruby
class MyAgent < ApplicationAgent
  has_context  # Enables auto-save of messages and generations

  def chat
    create_context(contextable: params[:user])
    prompt messages: context_messages
  end
end
```

#### HasTools

Declarative tool registration with auto-discovery from JSON templates:

```ruby
class ResearchAgent < ApplicationAgent
  has_tools :navigate, :click, :extract_text  # Load from views/tools/*.json.erb

  tool :custom_action do  # Or define inline
    description "Perform a custom action"
    parameter :input, type: :string, required: true
  end

  def navigate(url:)
    # Tool implementation called by AI
  end
end
```

#### StreamsToolUpdates

Broadcasts tool execution status to the frontend via ActionCable:

```ruby
class ResearchAgent < ApplicationAgent
  tool_description :navigate, ->(args) { "Visiting #{args[:url]}..." }
  tool_description :extract_text, "Reading page content..."
end
```

## Available Agents

### WritingAssistantAgent

AI-powered writing enhancement with 6 actions:

| Action | Description |
|--------|-------------|
| `improve` | Enhance writing quality, clarity, and engagement |
| `grammar` | Fix grammar, punctuation, and spelling |
| `style` | Adjust writing style and tone |
| `summarize` | Create concise summaries |
| `expand` | Elaborate and add detail to content |
| `brainstorm` | Generate creative ideas and suggestions |

### ResearchAssistantAgent

Autonomous web research using Capybara/Cuprite browser automation:

| Tool | Description |
|------|-------------|
| `navigate` | Visit URLs |
| `click` | Click elements by selector or text |
| `fill_form` | Fill form fields |
| `extract_text` | Extract text from selectors |
| `extract_main_content` | Smart content detection |
| `extract_links` | Get visible links from page |
| `page_info` | Analyze page structure |
| `go_back` | Navigate back in history |

### FileAnalyzerAgent

Document and image analysis with vision model support:

| Action | Description |
|--------|-------------|
| `analyze_pdf` | Extract and analyze PDF content |
| `analyze_image` | Vision-based image description |
| `extract_image_text` | OCR-style text extraction |
| `extract_text` | Generic file text extraction |
| `summarize_document` | Document summarization |

## Setup

### 1. Install Dependencies

```bash
bundle install
```

### 2. Configure API Keys

Add to your environment or Rails credentials:

```bash
# .env or environment variables
OPENAI_API_KEY=your_openai_api_key
ANTHROPIC_API_KEY=your_anthropic_api_key  # Optional
```

### 3. Database Setup

Run migrations for agent context tables:

```bash
bin/rails db:migrate
```

This creates:
- `agent_contexts` - Conversation sessions
- `agent_messages` - Individual messages (user/assistant/tool)
- `agent_generations` - Response metadata and token usage

### 4. Configure Providers

Edit `config/active_agent.yml`:

```yaml
development:
  openai:
    service: "OpenAI"
    api_key: <%= ENV['OPENAI_API_KEY'] %>
    model: "gpt-4o"
    temperature: 0.7
```

## Usage

### Controller Integration

```ruby
# Synchronous
result = WritingAssistantAgent.with(
  content: params[:content],
  contextable: @page
).improve.generate_now

# Asynchronous with streaming
stream_id = SecureRandom.hex(8)
WritingAssistantAgent.with(
  content: params[:content],
  stream_id: stream_id
).improve.generate_later
```

### Frontend Streaming

Subscribe to ActionCable channel with the stream_id:

```javascript
const channel = consumer.subscriptions.create(
  { channel: "AssistantStreamChannel", stream_id: streamId },
  {
    received(data) {
      if (data.content) {
        // Append streamed content
      }
      if (data.tool_status) {
        // Show tool execution status
      }
      if (data.done) {
        // Generation complete
      }
    }
  }
)
```

### Adding New Agents

1. Create agent class:

```ruby
# app/agents/my_agent.rb
class MyAgent < ApplicationAgent
  has_context
  has_tools :my_tool

  def my_action
    create_context(contextable: params[:record])
    prompt(tools: tools)
  end

  def my_tool(param:)
    # Tool implementation
    { success: true, result: "..." }
  end
end
```

2. Create prompt templates:

```erb
<%# app/views/my_agent/my_action.text.erb %>
Please help with: <%= @task %>
```

3. Create tool schemas:

```json
<%# app/views/my_agent/tools/my_tool.json.erb %>
{
  "type": "function",
  "name": "my_tool",
  "description": "Does something useful",
  "parameters": {
    "type": "object",
    "properties": {
      "param": { "type": "string", "description": "Input parameter" }
    },
    "required": ["param"]
  }
}
```

## Database Models

### AgentContext

Stores conversation sessions with polymorphic association:

```ruby
context = AgentContext.create!(
  contextable: page,           # Any record (Page, Book, User, etc.)
  agent_name: "WritingAssistantAgent",
  action_name: "improve"
)

context.add_user_message("Please improve this text")
context.record_generation!(response)
```

### AgentMessage

Individual conversation turns:

```ruby
message.role      # "system", "user", "assistant", "tool"
message.content   # Message text
message.to_message_hash  # Convert to ActiveAgent format
```

### AgentGeneration

Response metadata with token tracking:

```ruby
generation.input_tokens    # Tokens in prompt
generation.output_tokens   # Tokens in response
generation.total_tokens    # Total usage
generation.duration_ms     # Response time
generation.usage           # AgentUsage object
```

## Documentation

- [Active Agents Integration](docs/active-agents-integration.md) - Detailed implementation guide
- [Research Assistant](docs/features/research-assistant.md) - Web research feature docs
- [Claude Integration Guide](docs/CLAUDE.md) - Agent development patterns

## Original Writebook

For the base Writebook functionality (books, pages, users, publishing), see the [original Writebook repository](https://github.com/basecamp/writebook).

## License

This fork maintains the original Writebook license. The AI integration uses:
- [ActiveAgent](https://github.com/activeagents/activeagent) - MIT License
- [SolidAgent](https://github.com/activeagents/solid_agent) - MIT License
