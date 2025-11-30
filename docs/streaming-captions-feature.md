# Streaming Captions and AI Features

## Overview

This document describes the implementation of real-time streaming for AI-generated image captions and all writing assistant features in Writebook.

## Feature: Streaming Image Captions

### What Was Implemented

When a user uploads an image to a Writebook page:
1. The image renders immediately in the markdown editor
2. An AI-generated caption streams in real-time below the image
3. The caption appears as it's being generated, providing immediate feedback

### Technical Implementation

#### Backend Changes

**1. FileAnalyzerAgent** (`app/agents/file_analyzer_agent.rb`)
- Added `stream: true` to enable streaming
- Implemented `on_stream :broadcast_chunk` callback
- Implemented `on_stream_close :broadcast_complete` callback
- Broadcasts caption chunks via ActionCable as they're generated

**2. UploadsController** (`app/controllers/action_text/markdown/uploads_controller.rb`)
- Modified `create` action to:
  - Return image URL immediately (no blocking wait for caption)
  - Generate unique `stream_id` for each upload
  - Start caption generation asynchronously with `generate_later`
  - Include `stream_id` in JSON response

**3. JSON Response** (`app/views/action_text/markdown/uploads/create.json.jbuilder`)
- Added `streamId` field to response
- Removed blocking `caption` field

#### Frontend Changes

**1. Markdown Upload Controller** (`app/javascript/controllers/markdown_upload_controller.js`)
- Imported ActionCable consumer
- Modified `insertImageIntoEditor`:
  - Inserts image markdown immediately
  - Adds placeholder caption: `*Generating caption...*`
  - Calls `streamCaption` if `streamId` is present
- Added `streamCaption` method:
  - Subscribes to ActionCable with stream_id
  - Accumulates caption chunks as they arrive
  - Updates caption in real-time via `updateCaption`
  - Handles completion and errors
- Added `updateCaption` method:
  - Finds image markdown by URL
  - Replaces caption text using regex pattern
  - Triggers editor input events for live preview

### User Experience

1. User clicks "Upload File" button
2. Selects an image
3. Image appears immediately in editor: `![filename](url)`
4. Caption placeholder appears: `*Generating caption...*`
5. Caption text streams in character-by-character
6. Final caption replaces placeholder: `*An AI-generated description of the image*`

## Feature: Streaming All Writing Assistant Actions

### What Was Implemented

All AI writing assistant features now stream their responses in real-time:
- ✓ Improve Writing
- ✓ Grammar Check
- ✓ Style Adjustment
- ✓ Summarize
- ✓ Expand
- ✓ Brainstorm

### Technical Implementation

#### Backend Changes

**1. AssistantsController** (`app/controllers/assistants_controller.rb`)

Added a **single streaming endpoint** (`stream`) that routes to all agent actions:
- Accepts `action_type` parameter to determine which action to execute
- Supported actions: `improve`, `grammar`, `style`, `summarize`, `expand`, `brainstorm`
- Generates unique `stream_id`
- Routes to appropriate agent method via `case` statement
- Calls agent with `generate_later`
- Returns `stream_id` to client
- Agent broadcasts chunks via ActionCable
- Includes error handling for unknown actions

**2. Routes** (`config/routes.rb`)

Simplified to a single streaming route:
```ruby
# Single streaming endpoint for all writing actions
post "stream" => "assistants#stream"
```

Legacy non-streaming endpoints kept for backwards compatibility.

#### Frontend Changes

**1. Assistant Controller** (`app/javascript/controllers/assistant_controller.js`)

- Removed unused `post` import (no longer needed)
- Created a **single `streamAction` method** that handles all streaming requests
- All AI methods now call `streamAction` with their specific action type:
  - `improveWriting(content)` → `streamAction('improve', { content })`
  - `checkGrammar(content)` → `streamAction('grammar', { content })`
  - `expandText(content)` → `streamAction('expand', { content })`
  - `summarizeText(content)` → `streamAction('summarize', { content })`
  - `adjustStyle(content)` → `streamAction('style', { content, style_guide })`
  - `brainstormIdeas(topic)` → `streamAction('brainstorm', { topic, number_of_ideas })`
- `streamAction` method:
  - Accepts `actionType` and `data` parameters
  - Makes POST to `/assistants/stream` with `action_type` parameter
  - Handles ActionCable subscription
  - Accumulates and displays content in real-time
- Updated `handleAIAction` to treat all actions as streaming
- Removed conditional logic for streaming vs non-streaming

### User Experience

1. User selects text in editor
2. Clicks an AI button (e.g., "Improve")
3. Editor clears and shows blank state
4. AI response streams in character-by-character
5. User sees response being generated in real-time
6. Editor auto-updates with complete response

## Architecture

### Streaming Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Browser   │────▶│  Controller  │────▶│   Agent     │
│   Upload    │     │  (Rails)     │     │  (Async)    │
└─────────────┘     └──────────────┘     └─────────────┘
       ▲                    │                     │
       │                    │                     │
       │                    ▼                     ▼
       │            ┌──────────────┐     ┌─────────────┐
       │            │  Return      │     │  OpenAI API │
       │◀───────────│  stream_id   │     │  (Streaming)│
       │            └──────────────┘     └─────────────┘
       │                                         │
       │                                         ▼
       │                                 ┌─────────────┐
       │                                 │  on_stream  │
       │                                 │  Callback   │
       │                                 └─────────────┘
       │                                         │
       │            ┌──────────────┐            │
       └────────────│ ActionCable  │◀───────────┘
                    │  Broadcast   │
                    └──────────────┘
```

## Benefits

### User Benefits
1. **Immediate Feedback**: Users see results as they're generated
2. **Better UX**: No blocking waits for AI responses
3. **Perceived Speed**: Streaming feels faster than waiting
4. **Real-time Updates**: Live preview updates as text streams
5. **Consistent Interface**: All AI features work the same way

### Developer Benefits (Single Streaming Endpoint)
1. **DRY Principle**: Single endpoint handles all streaming actions
2. **Easier Maintenance**: Changes to streaming logic only need to be made once
3. **Simpler Routing**: One route instead of six separate routes
4. **Reduced Code Duplication**: Shared streaming logic across all actions
5. **Easier to Extend**: Adding new actions requires minimal code changes
6. **Better Error Handling**: Centralized error handling for all streaming actions

## Testing

### Manual Testing

1. **Image Caption Streaming**:
   - Upload an image in edit mode
   - Verify image appears immediately
   - Watch caption stream in below image
   - Check final caption is properly formatted

2. **Writing Assistant Streaming**:
   - Select text in editor
   - Click "Improve" button
   - Watch response stream into editor
   - Verify preview updates in real-time
   - Repeat for all AI buttons

### Browser Console

Monitor streaming with console logs:
```javascript
// Caption streaming logs
[Caption Streaming] Starting for stream_id: image_caption_abc123
[Caption Streaming] Connected to AssistantStreamChannel
[Caption Streaming] Message received: { content: "A beautiful..." }
[Caption Streaming] Streaming complete

// Writing assistant logs
[ActionCable] Connected to AssistantStreamChannel
[ActionCable] Content chunk received, length: 45
[ActionCable] Streaming complete
```

## Files Modified

### Backend
- `app/agents/file_analyzer_agent.rb`
- `app/controllers/action_text/markdown/uploads_controller.rb`
- `app/views/action_text/markdown/uploads/create.json.jbuilder`
- `app/controllers/assistants_controller.rb`
- `config/routes.rb`

### Frontend
- `app/javascript/controllers/markdown_upload_controller.js`
- `app/javascript/controllers/assistant_controller.js`

### Infrastructure (Already Existed)
- `app/channels/assistant_stream_channel.rb` (shared by all features)
- `app/agents/writing_assistant_agent.rb` (already had streaming enabled)

## Adding a New Streaming Action

Thanks to the single endpoint architecture, adding a new AI action is straightforward:

### 1. Add Agent Method
```ruby
# app/agents/writing_assistant_agent.rb
def translate
  @content = params[:content]
  @target_language = params[:target_language]
  @task = "translate the content"
  prompt
end
```

### 2. Add Case to Controller
```ruby
# app/controllers/assistants_controller.rb (in the stream action)
when 'translate'
  agent.translate.generate_later
```

### 3. Add Frontend Method
```javascript
// app/javascript/controllers/assistant_controller.js
async translateText(content, language) {
  return await this.streamAction('translate', {
    content,
    target_language: language
  })
}
```

That's it! The routing, ActionCable setup, and streaming logic are all handled automatically.

## Future Enhancements

- [ ] Add visual streaming indicator (typing animation)
- [ ] Implement retry logic for failed streams
- [ ] Add ability to cancel streaming mid-generation
- [ ] Cache frequently used captions
- [ ] Support for custom caption detail levels
- [ ] Batch caption generation for multiple images
- [ ] Add translate action (example above)
- [ ] Add tone analysis action
- [ ] Add content suggestions action

## Notes

- ActionCable handles WebSocket connections automatically
- Stream IDs are unique per request to prevent collisions
- Agent callbacks broadcast to specific stream IDs
- Frontend subscribes and accumulates chunks
- All streaming uses the shared `AssistantStreamChannel`
