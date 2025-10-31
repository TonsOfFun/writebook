# Active Agents AI Integration for Writebook

## Overview

This document describes the integration of Active Agents AI framework into Writebook, providing AI-powered writing assistance features directly in the editor.

## Features Implemented

### 1. Writing Assistant Agent
The `WritingAssistantAgent` provides the following AI-powered features:

- **Improve Writing**: Enhances text quality, clarity, and engagement
- **Grammar Check**: Corrects grammar, punctuation, and spelling errors
- **Style Adjustment**: Adjusts writing style and tone based on guidelines
- **Summarize**: Creates concise summaries of longer texts
- **Expand**: Elaborates and expands on existing content
- **Brainstorm**: Generates creative ideas and suggestions

### 2. File Analyzer Agent
The `FileAnalyzerAgent` provides document analysis capabilities:

- **PDF Analysis**: Extracts and analyzes content from PDF files
- **Image Analysis**: Describes and analyzes images using vision models
- **Text Extraction**: Extracts text from various file formats
- **Document Summarization**: Creates summaries of uploaded documents

## Installation & Setup

### 1. Dependencies Added

Added to `Gemfile`:
```ruby
# AI Integration
gem "activeagent"
gem "ruby-openai"  # For OpenAI support
gem "ruby-anthropic"  # For Anthropic/Claude support
gem "pdf-reader"  # For PDF analysis
```

### 2. Configuration

Created `config/active_agent.yml` with support for multiple AI providers:
```yaml
development:
  openai:
    service: "OpenAI"
    api_key: <%= ENV['OPENAI_API_KEY'] %>
    model: "gpt-4o-mini"

  anthropic:
    service: "Anthropic"
    api_key: <%= ENV['ANTHROPIC_API_KEY'] %>
    model: "claude-3-5-sonnet-latest"
```

### 3. Environment Variables

Add to `.env`:
```bash
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

## Implementation Details

### Backend Components

1. **Agents** (`app/agents/`)
   - `ApplicationAgent`: Base agent configuration
   - `WritingAssistantAgent`: Writing enhancement features
   - `FileAnalyzerAgent`: File analysis capabilities

2. **Controller** (`app/controllers/ai_assistants_controller.rb`)
   - RESTful endpoints for each AI action
   - JSON responses for frontend integration
   - Error handling and authentication

3. **Routes** (`config/routes.rb`)
   ```ruby
   namespace :ai_assistants do
     post "writing/improve"
     post "writing/grammar"
     post "writing/style"
     post "writing/summarize"
     post "writing/expand"
     post "writing/brainstorm"
     post "analyze_file"
   end
   ```

### Frontend Components

1. **Toolbar Integration** (`app/views/pages/_house_toolbar.html.erb`)
   - Added AI action buttons to the House editor toolbar
   - Icons and tooltips for each AI feature
   - Visual separator for AI tools section

2. **Stimulus Controller** (`app/javascript/controllers/ai_assistant_controller.js`)
   - Handles button clicks and API calls
   - Text selection and replacement
   - Loading states and error handling
   - Integration with House markdown editor

3. **Styling** (`app/assets/stylesheets/ai_assistant.css`)
   - Button styling and hover effects
   - Loading animations
   - Tooltips for AI actions

## Usage

### For End Users

1. **Open a page for editing** in Writebook
2. **Select text** in the editor (or leave unselected to process entire content)
3. **Click an AI button** in the toolbar:
   - 🔧 **Improve**: Enhance writing quality
   - ✓ **Grammar**: Fix grammar and spelling
   - ↔️ **Expand**: Add more detail
   - 📝 **Summarize**: Create a summary

### For Developers

#### Adding a New AI Action

1. Add the action to the agent:
```ruby
# app/agents/writing_assistant_agent.rb
def new_action(content:, options: {})
  @content = content
  @options = options
  prompt
end
```

2. Create a prompt template:
```erb
# app/views/writing_assistant_agent/new_action.text.erb
Please perform new action on this content:
<%= @content %>
```

3. Add controller endpoint:
```ruby
# app/controllers/ai_assistants_controller.rb
def writing_new_action
  agent = WritingAssistantAgent.new
  result = agent.new_action(content: params[:content])
  render json: { result: result.generate_now }
end
```

4. Add route and frontend integration

## Testing

### Manual Testing Steps

1. Start the Rails server: `bin/dev`
2. Navigate to http://localhost:3011
3. Open a book and enter edit mode
4. Test each AI feature:
   - Select text and click "Improve"
   - Click "Grammar" to check entire page
   - Use "Expand" on a paragraph
   - Generate a summary of the content

### Integration Points Verified

- ✅ Active Agent gem installation
- ✅ Agent classes created and configured
- ✅ Controller endpoints functional
- ✅ Toolbar buttons visible in edit mode
- ✅ Stimulus controller binds to buttons
- ✅ API routes configured

## Architecture Diagram

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Browser   │────▶│  Stimulus    │────▶│   Rails     │
│   Editor    │◀────│  Controller  │◀────│ Controller  │
└─────────────┘     └──────────────┘     └─────────────┘
                                                 │
                                                 ▼
                                        ┌─────────────┐
                                        │   Active    │
                                        │   Agents    │
                                        └─────────────┘
                                                 │
                                    ┌────────────┴────────────┐
                                    ▼                         ▼
                            ┌─────────────┐          ┌─────────────┐
                            │   OpenAI    │          │  Anthropic  │
                            │     API     │          │     API     │
                            └─────────────┘          └─────────────┘
```

## Troubleshooting

### Common Issues

1. **API Keys Not Working**
   - Ensure environment variables are set
   - Restart Rails server after adding `.env`
   - Check credentials in Rails console

2. **Buttons Not Appearing**
   - Verify you're in edit mode
   - Check browser console for JS errors
   - Ensure Stimulus controller is loaded

3. **AI Requests Failing**
   - Check Rails logs for errors
   - Verify network connectivity
   - Ensure API quotas aren't exceeded

## Future Enhancements

- [ ] Add streaming responses for real-time feedback
- [ ] Implement custom writing style profiles
- [ ] Add support for more AI providers (Ollama, etc.)
- [ ] Create collaborative AI features
- [ ] Add AI-powered search and navigation
- [ ] Implement context-aware suggestions
- [ ] Add translation capabilities
- [ ] Create AI writing analytics

## Security Considerations

- API keys stored in environment variables
- Authentication required for all AI endpoints
- Rate limiting should be implemented
- Input sanitization for AI prompts
- CSRF protection enabled

## Performance Notes

- AI requests are asynchronous
- Loading states prevent multiple simultaneous requests
- Responses cached where appropriate
- Text selection preserved during operations

## License

This integration follows the MIT License of the Active Agent gem.