# Active Agent Integration Guide for Writebook

## Overview
This document describes how to properly integrate and use the Active Agent gem in the Writebook application for AI-powered features.

## Understanding Active Agent

Active Agent is a Rails gem that provides a framework for integrating AI services (like OpenAI, Anthropic) into Rails applications. It follows a pattern similar to Action Mailer but for AI agents.

## Key Components

### 1. Agent Classes
Agents inherit from `ApplicationAgent` (which inherits from `ActiveAgent::Base`) and define AI-powered actions.

```ruby
class WritingAssistantAgent < ApplicationAgent
  generate_with :openai,
    model: "gpt-4o-mini",
    instructions: "You are an expert writing assistant..."

  def improve
    @action = "improve the writing"
    prompt  # This renders the view template
  end
end
```

### 2. Agent Views
Each agent action has a corresponding view template in `app/views/{agent_name}/`:

```erb
# app/views/writing_assistant_agent/improve.text.erb
Please <%= @action %> the following content:
<%= @content %>
```

### 3. Controller Integration
Controllers use the Agent with `.with()` to pass parameters and `.generate_now` to execute:

```ruby
def writing_improve
  result = WritingAssistantAgent.with(
    content: params[:content],
    context: params[:context]
  ).improve.generate_now  # Important: call generate_now to execute

  render json: { improved_content: result }
end
```

## Important Patterns

### The `prompt` Method
- The `prompt` method is provided by Active Agent
- It renders the corresponding view template and prepares it for AI generation
- Always return `prompt` from agent action methods

### The `generate_now` Method
- Must be called on the agent instance to actually execute the AI generation
- Returns the AI-generated response as a string
- Called in the controller, not in the agent class

### Parameter Passing
- Use `.with()` to pass parameters to the agent
- Access parameters in the agent using instance variables or params hash
- Instance variables set in the agent are available in the view templates

## Configuration

### config/active_agent.yml
```yaml
development:
  openai:
    service: "OpenAI"
    api_key: <%= ENV['OPENAI_API_KEY'] || Rails.application.credentials.dig(:openai, :api_key) %>
    model: "gpt-4o-mini"
    temperature: 0.7

  anthropic:
    service: "Anthropic"
    api_key: <%= ENV['ANTHROPIC_API_KEY'] || Rails.application.credentials.dig(:anthropic, :api_key) %>
    model: "claude-3-5-sonnet-latest"
    temperature: 0.7
```

## Common Pitfalls and Solutions

### 1. Stack Level Too Deep Error
**Problem**: Calling a non-existent method or creating infinite recursion.

**Solution**: Ensure agent methods return `prompt`, not `self` or recursive calls.

### 2. Missing generate_now Call
**Problem**: Agent returns an object instead of generated text.

**Solution**: Always call `.generate_now` in the controller:
```ruby
# Wrong
result = Agent.with(params).action
# Right
result = Agent.with(params).action.generate_now
```

### 3. Missing View Template
**Problem**: Rails can't find the template for the agent action.

**Solution**: Create a corresponding view file in `app/views/{agent_name}/{action}.text.erb`

## Testing AI Features

### Manual Testing with Browser
1. Ensure API keys are configured in Rails credentials or environment variables
2. Start the Rails server
3. Navigate to a page with AI features
4. Select text and click AI assistant buttons
5. Check server logs for API calls and responses

### JavaScript Integration
The Stimulus controller should:
1. Capture selected text
2. Make POST request to the assistant endpoint
3. Handle the JSON response
4. Update the editor with AI-generated content

```javascript
async improveWriting(content) {
  return await post('/assistants/writing/improve', {
    body: JSON.stringify({ content }),
    responseKind: 'json',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    }
  })
}
```

## File Structure
```
app/
├── agents/
│   ├── application_agent.rb
│   ├── writing_assistant_agent.rb
│   └── file_analyzer_agent.rb
├── controllers/
│   └── assistants_controller.rb
├── javascript/controllers/
│   └── assistant_controller.js
└── views/
    ├── writing_assistant_agent/
    │   ├── improve.text.erb
    │   ├── grammar.text.erb
    │   └── ...
    └── layouts/
        └── agent.text.erb
```

## Debugging Tips

1. **Check Rails Logs**: Look for the full request/response cycle
2. **Verify API Keys**: Ensure credentials are properly configured
3. **Test Agent Directly**: Use Rails console to test agents:
   ```ruby
   WritingAssistantAgent.with(content: "test").improve.generate_now
   ```
4. **Check View Rendering**: Verify templates are being found and rendered
5. **Monitor API Calls**: Check if external API calls are being made

## Future Enhancements

- Add response caching to reduce API costs
- Implement streaming responses for long content
- Add support for more AI providers
- Create agent tests with mocked API responses
- Add rate limiting and usage tracking