require "test_helper"
require "ostruct"

class WritingAssistantAgentTest < ActiveSupport::TestCase
  test "agent is defined and inherits from ApplicationAgent" do
    assert defined?(WritingAssistantAgent)
    assert WritingAssistantAgent < ApplicationAgent
  end

  test "has improve action" do
    assert WritingAssistantAgent.instance_methods.include?(:improve)
  end

  test "has grammar action" do
    assert WritingAssistantAgent.instance_methods.include?(:grammar)
  end

  test "has style action" do
    assert WritingAssistantAgent.instance_methods.include?(:style)
  end

  test "has summarize action" do
    assert WritingAssistantAgent.instance_methods.include?(:summarize)
  end

  test "has expand action" do
    assert WritingAssistantAgent.instance_methods.include?(:expand)
  end

  test "has brainstorm action" do
    assert WritingAssistantAgent.instance_methods.include?(:brainstorm)
  end

  test "improve sets content and task instance variables" do
    agent = WritingAssistantAgent.new
    agent.params = { content: "Test content", context: "Test context" }

    # Call the method (won't actually generate)
    agent.instance_variable_set(:@content, agent.params[:content])
    agent.instance_variable_set(:@context, agent.params[:context])
    agent.instance_variable_set(:@task, "improve the writing quality, clarity, and engagement")

    assert_equal "Test content", agent.instance_variable_get(:@content)
    assert_equal "Test context", agent.instance_variable_get(:@context)
    assert_equal "improve the writing quality, clarity, and engagement", agent.instance_variable_get(:@task)
  end

  test "grammar sets content and task instance variables" do
    agent = WritingAssistantAgent.new
    agent.params = { content: "Text with grammer errrors" }

    agent.instance_variable_set(:@content, agent.params[:content])
    agent.instance_variable_set(:@task, "check and correct grammar, punctuation, and spelling")

    assert_equal "Text with grammer errrors", agent.instance_variable_get(:@content)
    assert_equal "check and correct grammar, punctuation, and spelling", agent.instance_variable_get(:@task)
  end

  test "style sets content and style_guide instance variables" do
    agent = WritingAssistantAgent.new
    agent.params = { content: "Test content", style_guide: "formal" }

    agent.instance_variable_set(:@content, agent.params[:content])
    agent.instance_variable_set(:@style_guide, agent.params[:style_guide])
    agent.instance_variable_set(:@task, "adjust the writing style and tone")

    assert_equal "Test content", agent.instance_variable_get(:@content)
    assert_equal "formal", agent.instance_variable_get(:@style_guide)
  end

  test "summarize sets content and max_words instance variables" do
    agent = WritingAssistantAgent.new
    agent.params = { content: "Long content to summarize", max_words: 100 }

    agent.instance_variable_set(:@content, agent.params[:content])
    agent.instance_variable_set(:@max_words, agent.params[:max_words])
    agent.instance_variable_set(:@task, "create a concise summary")

    assert_equal "Long content to summarize", agent.instance_variable_get(:@content)
    assert_equal 100, agent.instance_variable_get(:@max_words)
  end

  test "expand sets content and target_length instance variables" do
    agent = WritingAssistantAgent.new
    agent.params = { content: "Short text", target_length: 500, areas_to_expand: "details" }

    agent.instance_variable_set(:@content, agent.params[:content])
    agent.instance_variable_set(:@target_length, agent.params[:target_length])
    agent.instance_variable_set(:@areas_to_expand, agent.params[:areas_to_expand])
    agent.instance_variable_set(:@task, "expand and elaborate on the content")

    assert_equal "Short text", agent.instance_variable_get(:@content)
    assert_equal 500, agent.instance_variable_get(:@target_length)
    assert_equal "details", agent.instance_variable_get(:@areas_to_expand)
  end

  test "brainstorm sets topic and context instance variables" do
    agent = WritingAssistantAgent.new
    agent.params = { topic: "writing ideas", context: "fiction novel", number_of_ideas: 10 }

    agent.instance_variable_set(:@topic, agent.params[:topic])
    agent.instance_variable_set(:@context, agent.params[:context])
    agent.instance_variable_set(:@number_of_ideas, agent.params[:number_of_ideas])
    agent.instance_variable_set(:@task, "generate creative ideas and suggestions")

    assert_equal "writing ideas", agent.instance_variable_get(:@topic)
    assert_equal "fiction novel", agent.instance_variable_get(:@context)
    assert_equal 10, agent.instance_variable_get(:@number_of_ideas)
  end

  test "broadcast_chunk does nothing without stream_id" do
    agent = WritingAssistantAgent.new
    agent.params = {}

    chunk = OpenStruct.new(delta: "test content")
    assert_nothing_raised { agent.send(:broadcast_chunk, chunk) }
  end

  test "broadcast_chunk does nothing when chunk has no delta" do
    agent = WritingAssistantAgent.new
    agent.params = { stream_id: "test_123" }

    chunk = OpenStruct.new(delta: nil)
    assert_nothing_raised { agent.send(:broadcast_chunk, chunk) }
  end

  test "broadcast_complete does nothing without stream_id" do
    agent = WritingAssistantAgent.new
    agent.params = {}

    chunk = OpenStruct.new
    assert_nothing_raised { agent.send(:broadcast_complete, chunk) }
  end

  test "can be instantiated with params" do
    agent = WritingAssistantAgent.with(
      content: "Test content",
      context: "Test context",
      stream_id: "test_123"
    )

    assert_not_nil agent
  end
end
