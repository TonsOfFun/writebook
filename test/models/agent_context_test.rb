require "test_helper"

class AgentContextTest < ActiveSupport::TestCase
  test "creates context with required attributes" do
    context = AgentContext.create!(
      agent_name: "TestAgent",
      action_name: "test_action",
      instructions: "You are a helpful assistant."
    )

    assert context.persisted?
    assert_equal "TestAgent", context.agent_name
    assert_equal "test_action", context.action_name
    assert_equal "pending", context.status
  end

  test "creates context with polymorphic association" do
    book = Book.create!(title: "Test Book")
    context = AgentContext.create!(
      contextable: book,
      agent_name: "WritingAgent"
    )

    assert_equal book, context.contextable
    assert_equal "Book", context.contextable_type
    assert_equal book.id, context.contextable_id
  end

  test "adds user message" do
    context = AgentContext.create!(agent_name: "TestAgent")
    message = context.add_user_message("Hello!")

    assert message.persisted?
    assert_equal "user", message.role
    assert_equal "Hello!", message.content
    assert_equal 0, message.position
  end

  test "adds assistant message" do
    context = AgentContext.create!(agent_name: "TestAgent")
    message = context.add_assistant_message("Hi there!")

    assert message.persisted?
    assert_equal "assistant", message.role
    assert_equal "Hi there!", message.content
  end

  test "messages are ordered by position" do
    context = AgentContext.create!(agent_name: "TestAgent")
    context.add_user_message("First")
    context.add_assistant_message("Second")
    context.add_user_message("Third")

    positions = context.messages.pluck(:position)
    assert_equal [0, 1, 2], positions
  end

  test "converts to prompt options" do
    context = AgentContext.create!(
      agent_name: "TestAgent",
      instructions: "Be helpful.",
      options: { "temperature" => 0.7 }
    )
    context.add_user_message("Hello")
    context.add_assistant_message("Hi!")

    opts = context.to_prompt_options

    assert_equal "Be helpful.", opts[:instructions]
    assert_equal 0.7, opts[:temperature]
    assert_equal 2, opts[:messages].length
    assert_equal({ role: "user", content: "Hello" }, opts[:messages].first)
  end
end

class AgentMessageTest < ActiveSupport::TestCase
  setup do
    @context = AgentContext.create!(agent_name: "TestAgent")
  end

  test "creates message with required attributes" do
    message = AgentMessage.create!(
      agent_context: @context,
      role: "user",
      content: "Test content"
    )

    assert message.persisted?
    assert_equal "user", message.role
    assert_equal "Test content", message.content
  end

  test "validates role inclusion" do
    message = AgentMessage.new(agent_context: @context, role: "invalid", content: "Test")
    assert_not message.valid?
    assert_includes message.errors[:role], "is not included in the list"
  end

  test "converts to message hash" do
    message = AgentMessage.create!(
      agent_context: @context,
      role: "user",
      content: "Hello",
      name: "John"
    )

    hash = message.to_message_hash
    assert_equal({ role: "user", content: "Hello", name: "John" }, hash)
  end

  test "parses JSON from assistant message" do
    message = AgentMessage.create!(
      agent_context: @context,
      role: "assistant",
      content: 'Here is the result: {"name": "test", "value": 42}'
    )

    json = message.parsed_json
    assert_equal({ name: "test", value: 42 }, json)
  end

  test "creates from hash" do
    message = AgentMessage.from_active_agent_message(
      { role: "user", content: "Hello" },
      context: @context
    )

    assert message.persisted?
    assert_equal "user", message.role
    assert_equal "Hello", message.content
  end

  test "creates from string" do
    message = AgentMessage.from_active_agent_message("Hello", context: @context)

    assert message.persisted?
    assert_equal "user", message.role
    assert_equal "Hello", message.content
  end
end

class AgentGenerationTest < ActiveSupport::TestCase
  setup do
    @context = AgentContext.create!(agent_name: "TestAgent")
  end

  test "creates generation with usage data" do
    generation = AgentGeneration.create!(
      agent_context: @context,
      provider_id: "chatcmpl-123",
      model: "gpt-4o-mini",
      finish_reason: "stop",
      input_tokens: 100,
      output_tokens: 50,
      total_tokens: 150,
      status: "completed"
    )

    assert generation.persisted?
    assert_equal 100, generation.input_tokens
    assert_equal 50, generation.output_tokens
    assert_equal 150, generation.total_tokens
  end

  test "provides usage object" do
    generation = AgentGeneration.create!(
      agent_context: @context,
      input_tokens: 100,
      output_tokens: 50,
      total_tokens: 150
    )

    usage = generation.usage
    assert_equal 100, usage.input_tokens
    assert_equal 50, usage.output_tokens
    assert_equal 150, usage.total_tokens
  end

  test "usage objects can be summed" do
    gen1 = AgentGeneration.create!(agent_context: @context, input_tokens: 100, output_tokens: 50, total_tokens: 150)
    gen2 = AgentGeneration.create!(agent_context: @context, input_tokens: 75, output_tokens: 25, total_tokens: 100)

    combined = gen1.usage + gen2.usage
    assert_equal 175, combined.input_tokens
    assert_equal 75, combined.output_tokens
    assert_equal 250, combined.total_tokens
  end

  test "success? returns true for completed status" do
    generation = AgentGeneration.create!(agent_context: @context, status: "completed")
    assert generation.success?
  end

  test "failed? returns true for failed status" do
    generation = AgentGeneration.create!(agent_context: @context, status: "failed", error_message: "Something went wrong")
    assert generation.failed?
  end
end

class AgentToolCallTest < ActiveSupport::TestCase
  setup do
    @context = AgentContext.create!(agent_name: "TestAgent")
  end

  test "creates tool call with required attributes" do
    tool_call = AgentToolCall.create!(
      agent_context: @context,
      name: "navigate",
      arguments: { url: "https://example.com" },
      status: "pending"
    )

    assert tool_call.persisted?
    assert_equal "navigate", tool_call.name
    assert_equal({ "url" => "https://example.com" }, tool_call.arguments)
    assert_equal "pending", tool_call.status
  end

  test "start! marks tool call as executing" do
    tool_call = AgentToolCall.create!(
      agent_context: @context,
      name: "navigate",
      status: "pending"
    )

    tool_call.start!

    assert_equal "executing", tool_call.status
    assert_not_nil tool_call.started_at
  end

  test "complete! marks tool call as completed with result" do
    tool_call = AgentToolCall.create!(
      agent_context: @context,
      name: "navigate",
      status: "executing",
      started_at: 1.second.ago
    )

    result = { success: true, current_url: "https://example.com" }
    tool_call.complete!(result)

    assert_equal "completed", tool_call.status
    assert_equal result.stringify_keys, tool_call.result
    assert_not_nil tool_call.completed_at
    assert_not_nil tool_call.duration_ms
  end

  test "fail! marks tool call as failed with error" do
    tool_call = AgentToolCall.create!(
      agent_context: @context,
      name: "navigate",
      status: "executing",
      started_at: 1.second.ago
    )

    tool_call.fail!("Connection timeout")

    assert_equal "failed", tool_call.status
    assert_equal "Connection timeout", tool_call.error_message
    assert_not_nil tool_call.completed_at
  end

  test "fail! accepts exception objects" do
    tool_call = AgentToolCall.create!(
      agent_context: @context,
      name: "navigate",
      status: "executing",
      started_at: 1.second.ago
    )

    tool_call.fail!(StandardError.new("Something went wrong"))

    assert_equal "failed", tool_call.status
    assert_equal "Something went wrong", tool_call.error_message
  end

  test "success? returns true for completed without error" do
    tool_call = AgentToolCall.create!(
      agent_context: @context,
      name: "navigate",
      status: "completed"
    )

    assert tool_call.success?
  end

  test "failed? returns true for failed status" do
    tool_call = AgentToolCall.create!(
      agent_context: @context,
      name: "navigate",
      status: "failed",
      error_message: "Error"
    )

    assert tool_call.failed?
  end

  test "in_progress? returns true for pending or executing" do
    pending_call = AgentToolCall.create!(agent_context: @context, name: "test", status: "pending")
    executing_call = AgentToolCall.create!(agent_context: @context, name: "test", status: "executing")

    assert pending_call.in_progress?
    assert executing_call.in_progress?
  end

  test "parsed_result returns symbolized keys" do
    tool_call = AgentToolCall.create!(
      agent_context: @context,
      name: "navigate",
      status: "completed",
      result: { "success" => true, "current_url" => "https://example.com" }
    )

    parsed = tool_call.parsed_result
    assert_equal({ success: true, current_url: "https://example.com" }, parsed)
  end

  test "parsed_arguments returns symbolized keys" do
    tool_call = AgentToolCall.create!(
      agent_context: @context,
      name: "navigate",
      arguments: { "url" => "https://example.com" }
    )

    parsed = tool_call.parsed_arguments
    assert_equal({ url: "https://example.com" }, parsed)
  end

  test "for_tool scope filters by tool name" do
    AgentToolCall.create!(agent_context: @context, name: "navigate")
    AgentToolCall.create!(agent_context: @context, name: "click")
    AgentToolCall.create!(agent_context: @context, name: "navigate")

    navigate_calls = @context.tool_calls.for_tool(:navigate)
    assert_equal 2, navigate_calls.count
  end

  test "statistics returns summary of tool calls" do
    AgentToolCall.create!(agent_context: @context, name: "navigate", status: "completed", duration_ms: 100)
    AgentToolCall.create!(agent_context: @context, name: "navigate", status: "completed", duration_ms: 150)
    AgentToolCall.create!(agent_context: @context, name: "click", status: "failed")

    stats = @context.tool_calls.statistics

    assert_equal 3, stats[:total]
    assert_equal 2, stats[:completed]
    assert_equal 1, stats[:failed]
    assert_equal 250, stats[:total_duration_ms]
    assert_equal({ "navigate" => 2, "click" => 1 }, stats[:by_tool])
  end

  test "position is auto-assigned" do
    call1 = AgentToolCall.create!(agent_context: @context, name: "navigate")
    call2 = AgentToolCall.create!(agent_context: @context, name: "click")
    call3 = AgentToolCall.create!(agent_context: @context, name: "extract_text")

    assert_equal 0, call1.position
    assert_equal 1, call2.position
    assert_equal 2, call3.position
  end
end

class AgentContextToolCallsTest < ActiveSupport::TestCase
  setup do
    @context = AgentContext.create!(agent_name: "TestAgent")
  end

  test "record_tool_call_start creates a tool call record" do
    tool_call = @context.record_tool_call_start(
      name: :navigate,
      arguments: { url: "https://example.com" },
      tool_call_id: "call_abc123"
    )

    assert tool_call.persisted?
    assert_equal "navigate", tool_call.name
    assert_equal({ "url" => "https://example.com" }, tool_call.arguments)
    assert_equal "call_abc123", tool_call.tool_call_id
    assert_equal "executing", tool_call.status
    assert_not_nil tool_call.started_at
  end

  test "record_tool_call_complete updates the tool call" do
    tool_call = @context.record_tool_call_start(name: :navigate, arguments: {})
    result = { success: true }

    @context.record_tool_call_complete(tool_call, result: result)

    tool_call.reload
    assert_equal "completed", tool_call.status
    assert_equal result.stringify_keys, tool_call.result
  end

  test "record_tool_call_failure updates the tool call with error" do
    tool_call = @context.record_tool_call_start(name: :navigate, arguments: {})

    @context.record_tool_call_failure(tool_call, error: "Connection failed")

    tool_call.reload
    assert_equal "failed", tool_call.status
    assert_equal "Connection failed", tool_call.error_message
  end

  test "tool_calls_for returns calls for specific tool" do
    @context.record_tool_call_start(name: :navigate, arguments: {})
    @context.record_tool_call_start(name: :click, arguments: {})
    @context.record_tool_call_start(name: :navigate, arguments: {})

    navigate_calls = @context.tool_calls_for(:navigate)
    assert_equal 2, navigate_calls.count
  end

  test "tool_call_results returns completed results with metadata" do
    tc1 = @context.record_tool_call_start(name: :navigate, arguments: { url: "https://example.com" })
    @context.record_tool_call_complete(tc1, result: { success: true, title: "Example" })

    tc2 = @context.record_tool_call_start(name: :extract_text, arguments: { selector: "body" })
    @context.record_tool_call_complete(tc2, result: { success: true, text: "Hello World" })

    results = @context.tool_call_results

    assert_equal 2, results.length
    assert_equal "navigate", results[0][:name]
    assert_equal({ url: "https://example.com" }, results[0][:arguments])
    assert_equal({ success: true, title: "Example" }, results[0][:result])
  end

  test "tool_results_for returns results for specific tool" do
    tc1 = @context.record_tool_call_start(name: :navigate, arguments: {})
    @context.record_tool_call_complete(tc1, result: { url: "https://a.com" })

    tc2 = @context.record_tool_call_start(name: :navigate, arguments: {})
    @context.record_tool_call_complete(tc2, result: { url: "https://b.com" })

    results = @context.tool_results_for(:navigate)

    assert_equal 2, results.length
    assert_equal({ url: "https://a.com" }, results[0])
    assert_equal({ url: "https://b.com" }, results[1])
  end

  test "tool_call_statistics returns summary" do
    tc1 = @context.record_tool_call_start(name: :navigate, arguments: {})
    @context.record_tool_call_complete(tc1, result: {})

    tc2 = @context.record_tool_call_start(name: :click, arguments: {})
    @context.record_tool_call_failure(tc2, error: "Element not found")

    stats = @context.tool_call_statistics

    assert_equal 2, stats[:total]
    assert_equal 1, stats[:completed]
    assert_equal 1, stats[:failed]
  end
end

class AgentReferenceTest < ActiveSupport::TestCase
  setup do
    @context = AgentContext.create!(agent_name: "ResearchAssistantAgent")
  end

  test "creates reference with required attributes" do
    ref = AgentReference.create!(
      agent_context: @context,
      url: "https://example.com/article",
      title: "Example Article"
    )

    assert ref.persisted?
    assert_equal "https://example.com/article", ref.url
    assert_equal "Example Article", ref.title
    assert_equal "example.com", ref.domain
    assert_equal "pending", ref.status
  end

  test "extracts domain from URL" do
    ref = AgentReference.create!(
      agent_context: @context,
      url: "https://docs.ruby-lang.org/en/3.2/String.html"
    )

    assert_equal "docs.ruby-lang.org", ref.domain
  end

  test "display_title returns og_title first" do
    ref = AgentReference.create!(
      agent_context: @context,
      url: "https://example.com",
      title: "Page Title",
      og_title: "OG Title"
    )

    assert_equal "OG Title", ref.display_title
  end

  test "display_title falls back to title" do
    ref = AgentReference.create!(
      agent_context: @context,
      url: "https://example.com",
      title: "Page Title"
    )

    assert_equal "Page Title", ref.display_title
  end

  test "display_title falls back to domain" do
    ref = AgentReference.create!(
      agent_context: @context,
      url: "https://example.com"
    )

    assert_equal "example.com", ref.display_title
  end

  test "to_markdown_link returns formatted link" do
    ref = AgentReference.create!(
      agent_context: @context,
      url: "https://example.com/article",
      title: "Example Article"
    )

    assert_equal "[Example Article](https://example.com/article)", ref.to_markdown_link
  end

  test "as_card returns hash for API" do
    ref = AgentReference.create!(
      agent_context: @context,
      url: "https://example.com/article",
      title: "Example Article",
      og_description: "This is a description",
      status: "complete"
    )

    card = ref.as_card

    assert_equal ref.id, card[:id]
    assert_equal "https://example.com/article", card[:url]
    assert_equal "example.com", card[:domain]
    assert_equal "Example Article", card[:title]
    assert_equal "This is a description", card[:description]
    assert_equal "[Example Article](https://example.com/article)", card[:markdown_link]
  end

  test "position is auto-assigned" do
    ref1 = AgentReference.create!(agent_context: @context, url: "https://a.com")
    ref2 = AgentReference.create!(agent_context: @context, url: "https://b.com")
    ref3 = AgentReference.create!(agent_context: @context, url: "https://c.com")

    assert_equal 0, ref1.position
    assert_equal 1, ref2.position
    assert_equal 2, ref3.position
  end

  test "with_metadata scope filters references" do
    AgentReference.create!(agent_context: @context, url: "https://a.com", title: "Has Title")
    AgentReference.create!(agent_context: @context, url: "https://b.com", og_title: "Has OG Title")
    AgentReference.create!(agent_context: @context, url: "https://c.com")  # No metadata

    refs = @context.references.with_metadata
    assert_equal 2, refs.count
  end
end

class AgentContextReferencesTest < ActiveSupport::TestCase
  setup do
    @context = AgentContext.create!(agent_name: "ResearchAssistantAgent")
  end

  test "extract_references! creates references from navigate tool calls" do
    # Create a completed navigate tool call
    tc = @context.tool_calls.create!(
      name: "navigate",
      arguments: { url: "https://example.com" },
      status: "completed",
      result: { success: true, current_url: "https://example.com", title: "Example" }
    )

    refs = @context.extract_references!

    assert_equal 1, @context.references.count
    ref = @context.references.first
    assert_equal "https://example.com", ref.url
    assert_equal "Example", ref.title
  end

  test "reference_cards returns formatted cards" do
    @context.references.create!(
      url: "https://example.com",
      title: "Example",
      status: "complete"
    )

    cards = @context.reference_cards
    assert_equal 1, cards.length
    assert_equal "https://example.com", cards.first[:url]
  end
end
