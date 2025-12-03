# Research Assistant AI Feature

## Overview

The Research Assistant is an AI-powered writing assistant that helps authors find and reference information on topics they're writing about. It performs automated web searches, fetches and parses relevant web pages, and synthesizes the findings into a well-organized research summary with proper citations.

## How It Works

1. **User Input**: Author provides a topic to research (either by typing or selecting text in the editor)
2. **Web Search**: Agent performs a DuckDuckGo search for the topic
3. **Page Fetching**: Top 3 most relevant pages are fetched and their content extracted
4. **AI Synthesis**: OpenAI GPT-4o analyzes the collected information and produces:
   - A comprehensive summary
   - Key facts and findings
   - Properly cited sources
   - Suggested text for the author's document

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌───────────────────┐
│  Editor/Modal   │────▶│   Controller     │────▶│  ResearchAgent    │
│  (Stimulus JS)  │◀────│  (Rails)         │◀────│  (ActiveAgent)    │
└─────────────────┘     └──────────────────┘     └───────────────────┘
                                                          │
                              ┌────────────────────────────┤
                              │                            │
                              ▼                            ▼
                     ┌─────────────────┐         ┌─────────────────┐
                     │  DuckDuckGo     │         │    OpenAI       │
                     │  HTML Search    │         │    GPT-4o       │
                     └─────────────────┘         └─────────────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │  Web Pages      │
                     │  (Nokogiri)     │
                     └─────────────────┘
```

## Files

### Agent
- `app/agents/research_assistant_agent.rb` - Main agent class with web search and page fetching capabilities

### Views
- `app/views/research_assistant_agent/research.text.erb` - Prompt template for AI synthesis
- `app/views/research_assistant_agent/instructions.text.erb` - System instructions

### Controller
- `app/controllers/assistants_controller.rb` - Added `research` action and streaming support

### Routes
- `config/routes.rb` - Added `post "research" => "assistants#research"`

### Frontend
- `app/views/pages/_house_toolbar.html.erb` - Added research button with search icon
- `app/javascript/controllers/ai_modal_controller.js` - Added 'Researching topic...' label

### Tests
- `test/agents/research_assistant_agent_test.rb` - Unit tests for the agent

## Usage

### From the Editor Toolbar

1. Open a page in edit mode
2. Optionally select text you want to research (or leave empty to use full content as topic)
3. Click the "Research" button (magnifying glass with + icon) in the AI tools section
4. The AI modal will open and show "Researching topic..."
5. Wait for the research to complete
6. Review the findings, then:
   - Click "Apply" to insert into document
   - Click "Copy" to copy to clipboard
   - Click "Discard" to close without changes

### Programmatic Usage

```ruby
# Non-streaming
result = ResearchAssistantAgent.with(
  topic: "climate change effects on coral reefs",
  context: "scientific article",
  depth: "standard"
).research.generate_now

# Streaming (via controller)
POST /assistants/stream
{
  "action_type": "research",
  "topic": "artificial intelligence in healthcare",
  "full_content": "Current document content...",
  "context": "Academic paper"
}
```

## Configuration

The research agent uses OpenAI GPT-4o for synthesis. Ensure you have set:

```bash
OPENAI_API_KEY=your_api_key_here
```

Or in Rails credentials:
```yaml
openai:
  api_key: your_api_key_here
```

## Web Search Implementation

The agent uses DuckDuckGo's HTML interface for searches (no API key required):

1. **Search**: Queries `html.duckduckgo.com/html/` with URL-encoded topic
2. **Parse Results**: Extracts titles, URLs, and snippets using Nokogiri
3. **Fetch Pages**: Downloads top 3 result pages with browser-like headers
4. **Extract Content**: Removes navigation, ads, scripts; keeps main content
5. **Limit Size**: Truncates content to prevent token overflow

## Output Format

The AI produces structured output:

```markdown
### Summary
2-4 paragraphs summarizing key findings

### Key Facts
- Bullet points of important facts
- Statistics and specific details

### Sources
1. [Source Title](URL) - Brief description
2. [Another Source](URL) - What it contributes

### Suggested Text
Paragraphs the author can incorporate with inline citations
```

## Limitations

- Searches limited to 8 results, fetches top 3 pages
- Page content truncated to 6000 characters each
- Some pages may block automated fetching
- Real-time/breaking news may not be immediately available
- No image or video analysis

## Future Enhancements

- [ ] Add support for specific domain searches (e.g., Wikipedia only)
- [ ] Implement caching of recent searches
- [ ] Add depth levels (quick/standard/thorough)
- [ ] Support for academic paper searches (arXiv, Google Scholar)
- [ ] Multi-query refinement based on initial results
- [ ] Fact-checking against multiple sources
