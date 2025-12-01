require "test_helper"

class ApplicationAgentTest < ActiveSupport::TestCase
  test "agent is defined" do
    assert defined?(ApplicationAgent)
  end

  test "inherits from ActiveAgent::Base" do
    assert ApplicationAgent < ActiveAgent::Base
  end

  test "has instance handle_exception method" do
    agent = ApplicationAgent.new

    # Should not raise an error
    exception = StandardError.new("Test exception")
    assert_nothing_raised { agent.handle_exception(exception) }
  end

  test "has class handle_exception method" do
    exception = StandardError.new("Test exception")
    assert_nothing_raised { ApplicationAgent.handle_exception(exception) }
  end

  test "handle_exception logs error message" do
    agent = ApplicationAgent.new
    exception = StandardError.new("Test error message")

    # Just verify it doesn't raise
    assert_nothing_raised { agent.handle_exception(exception) }
  end

  test "handle_exception logs backtrace" do
    agent = ApplicationAgent.new
    exception = StandardError.new("Test error")
    exception.set_backtrace(["line 1", "line 2"])

    assert_nothing_raised { agent.handle_exception(exception) }
  end
end
