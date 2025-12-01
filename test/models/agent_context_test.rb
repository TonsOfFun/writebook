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
    book = books(:one)
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
