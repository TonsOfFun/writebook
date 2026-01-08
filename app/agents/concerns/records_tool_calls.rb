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
# - Automatic extraction of references from research tool calls
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
# @example Accessing extracted references
#   agent.context.references                 #=> [AgentReference, ...]
#   agent.context.reference_cards            #=> [{url: ..., title: ...}, ...]
#
module RecordsToolCalls
  extend ActiveSupport::Concern

  included do
    class_attribute :_tool_recording_wrapped, default: Set.new
    class_attribute :_extracts_references, default: false
  end

  class_methods do
    # Enables automatic reference extraction after tool execution
    # Call this in agents that browse the web (like ResearchAssistantAgent)
    #
    # @example
    #   class ResearchAgent < ApplicationAgent
    #     extracts_references
    #   end
    def extracts_references
      self._extracts_references = true
    end

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

      # Extract references if enabled and this is a reference-worthy tool
      extract_reference_from_tool_call(tool_call, result) if should_extract_references?(tool_name)

      result
    rescue => e
      # Record failure
      context.record_tool_call_failure(tool_call, error: e)

      # Re-raise the exception so normal error handling continues
      raise
    end
  end

  # Determines if we should extract references from this tool call
  def should_extract_references?(tool_name)
    return false unless self.class._extracts_references
    return false unless context.present?

    # Only extract from navigation and content tools
    %i[navigate extract_main_content extract_links].include?(tool_name.to_sym)
  end

  # Extracts a reference from a completed tool call
  def extract_reference_from_tool_call(tool_call, result)
    return unless result.is_a?(Hash)
    return unless result[:success] || result["success"]

    case tool_call.name.to_sym
    when :navigate
      url = result[:current_url] || result["current_url"]
      title = result[:title] || result["title"]
      return unless url.present?

      ref = context.references.find_or_initialize_by(url: url)
      ref.agent_tool_call = tool_call
      ref.title = title if title.present?
      ref.status = "complete"
      ref.save!

    when :extract_main_content
      url = result[:current_url] || result["current_url"]
      return unless url.present?

      ref = context.references.find_by(url: url)
      if ref
        ref.update!(
          extracted_content: (result[:content] || result["content"])&.truncate(1000),
          title: (result[:title] || result["title"]) || ref.title
        )
      end

    when :extract_links
      links = result[:links] || result["links"]
      return unless links.is_a?(Array)

      links.first(10).each do |link| # Limit to first 10 links
        href = link[:href] || link["href"]
        next unless href.present? && href.start_with?("http")

        ref = context.references.find_or_initialize_by(url: href)
        next unless ref.new_record?

        ref.agent_tool_call = tool_call
        ref.title = link[:text] || link["text"]
        ref.status = "pending"
        ref.save!
      end
    end
  rescue => e
    Rails.logger.error "[RecordsToolCalls] Failed to extract reference: #{e.message}"
  end
end
