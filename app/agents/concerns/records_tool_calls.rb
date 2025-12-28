# frozen_string_literal: true

# RecordsToolCalls automatically captures tool call execution in the AgentContext.
#
# When an agent includes this concern and has a context, all tool method invocations
# are recorded with their arguments, results, timing, and success/failure status.
#
# This enables:
# - Audit trail of all tool calls made during an agent session
# - Performance analysis of tool execution times
# - Debugging by examining tool inputs/outputs
# - Building rich context from tool results for follow-up prompts
#
# @example Basic usage
#   class MyAgent < ApplicationAgent
#     include SolidAgent::HasContext
#     include SolidAgent::HasTools
#     include RecordsToolCalls
#
#     has_context
#     has_tools :search, :fetch
#
#     def research
#       create_context(contextable: params[:document])
#       prompt(tools: tools)
#     end
#   end
#
# @example Accessing recorded tool calls
#   agent = MyAgent.new
#   agent.research
#
#   agent.context.tool_calls.count           #=> 5
#   agent.context.tool_calls_for(:search)    #=> [AgentToolCall, ...]
#   agent.context.tool_call_results          #=> [{name: "search", result: {...}}, ...]
#
module RecordsToolCalls
  extend ActiveSupport::Concern

  included do
    class_attribute :_tool_recording_wrapped, default: Set.new
  end

  class_methods do
    # Wraps a tool method to record its execution in the context.
    #
    # This is called automatically for tools declared with has_tools or tool_description.
    #
    # @param tool_name [Symbol, String] the tool method name
    def wrap_tool_for_recording(tool_name)
      tool_sym = tool_name.to_sym
      return if _tool_recording_wrapped.include?(tool_sym)

      self._tool_recording_wrapped = _tool_recording_wrapped.dup.add(tool_sym)

      wrapper_module = Module.new do
        define_method(tool_sym) do |**kwargs|
          record_tool_execution(tool_sym, kwargs) { super(**kwargs) }
        end
      end

      prepend wrapper_module
    end

    # Hook into has_tools to automatically wrap tools for recording
    def has_tools(*tool_names)
      super
      # Wrap each declared tool for recording
      tool_names.each { |name| wrap_tool_for_recording(name) } if tool_names.any?
    end

    # Hook into tool_description to automatically wrap tools for recording
    def tool_description(tool_name, description)
      super
      wrap_tool_for_recording(tool_name)
    end
  end

  private

  # Records the execution of a tool call, capturing arguments, result, and timing.
  #
  # @param tool_name [Symbol] the tool being executed
  # @param arguments [Hash] the arguments passed to the tool
  # @yield the block that executes the actual tool method
  # @return [Object] the result from the tool
  def record_tool_execution(tool_name, arguments)
    # Skip recording if no context is available
    unless respond_to?(:context) && context.present?
      return yield
    end

    # Create the tool call record and mark it as started
    tool_call = context.record_tool_call_start(
      name: tool_name,
      arguments: arguments
    )

    begin
      # Execute the tool
      result = yield

      # Record successful completion
      context.record_tool_call_complete(tool_call, result: result)

      result
    rescue => e
      # Record failure
      context.record_tool_call_failure(tool_call, error: e)

      # Re-raise the exception so normal error handling continues
      raise
    end
  end
end
