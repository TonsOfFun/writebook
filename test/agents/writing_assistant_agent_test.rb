require "test_helper"

class WritingAssistantAgentTest < ActiveAgent::TestCase
  test "improve" do
    agent = WritingAssistantAgent.improve
    assert_equal "Improve", agent.prompt_context
  end

  test "grammar" do
    agent = WritingAssistantAgent.grammar
    assert_equal "Grammar", agent.prompt_context
  end

  test "style" do
    agent = WritingAssistantAgent.style
    assert_equal "Style", agent.prompt_context
  end

  test "summarize" do
    agent = WritingAssistantAgent.summarize
    assert_equal "Summarize", agent.prompt_context
  end

  test "expand" do
    agent = WritingAssistantAgent.expand
    assert_equal "Expand", agent.prompt_context
  end

  test "brainstorm" do
    agent = WritingAssistantAgent.brainstorm
    assert_equal "Brainstorm", agent.prompt_context
  end
end
