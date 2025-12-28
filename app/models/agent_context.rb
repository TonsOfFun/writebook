# AgentContext stores the overall context/conversation for agent generations.
#
# This model provides a "Rails way" of managing prompt context and generation
# history, mirroring ActiveAgent's ActionPrompt interface but persisted to the database.
#
# @example Creating a context for a page
#   context = AgentContext.create!(
#     contextable: page,
#     agent_name: "WritingAssistantAgent",
#     action_name: "improve",
#     instructions: "You are a helpful writing assistant."
#   )
#
# @example Adding messages to context
#   context.messages.create!(role: "user", content: "Please improve this text...")
#   context.messages.create!(role: "assistant", content: "Here's the improved version...")
#
# @example Accessing the latest generation
#   context.latest_generation.output_tokens #=> 150
#
class AgentContext < ApplicationRecord
  # Polymorphic association allows any model to have agent context
  belongs_to :contextable, polymorphic: true, optional: true

  # Messages in this conversation, ordered by position
  has_many :messages, -> { order(position: :asc) },
           class_name: "AgentMessage",
           dependent: :destroy

  # Generation results/responses
  has_many :generations,
           class_name: "AgentGeneration",
           dependent: :destroy

  # Tool call records - captures individual tool executions
  has_many :tool_calls,
           -> { order(position: :asc) },
           class_name: "AgentToolCall",
           dependent: :destroy

  # Validations
  validates :agent_name, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :for_agent, ->(name) { where(agent_name: name) }

  # Returns the latest generation for this context
  def latest_generation
    generations.order(created_at: :desc).first
  end

  # Returns all user messages
  def user_messages
    messages.where(role: "user")
  end

  # Returns all assistant messages
  def assistant_messages
    messages.where(role: "assistant")
  end

  # Adds a user message to the context
  def add_user_message(content, **attributes)
    messages.create!(role: "user", content: content, position: next_position, **attributes)
  end

  # Adds an assistant message to the context
  def add_assistant_message(content, **attributes)
    messages.create!(role: "assistant", content: content, position: next_position, **attributes)
  end

  # Adds a system message to the context
  def add_system_message(content, **attributes)
    messages.create!(role: "system", content: content, position: next_position, **attributes)
  end

  # Converts context to ActiveAgent-compatible prompt options hash
  def to_prompt_options
    {
      instructions: instructions,
      messages: messages.map(&:to_message_hash),
      **options.symbolize_keys
    }.compact
  end

  # Updates context from an ActiveAgent response
  def record_generation!(response)
    transaction do
      # Create the assistant message from the response
      response_message = if response.message
        add_assistant_message(
          response.message.content,
          name: response.message.try(:name)
        )
      end

      # Create the generation record
      generations.create!(
        response_message: response_message,
        provider_id: response.id,
        model: response.model,
        finish_reason: response.finish_reason,
        input_tokens: response.usage&.input_tokens || 0,
        output_tokens: response.usage&.output_tokens || 0,
        total_tokens: response.usage&.total_tokens || 0,
        cached_tokens: response.usage&.cached_tokens,
        reasoning_tokens: response.usage&.reasoning_tokens,
        duration_ms: response.usage&.duration_ms,
        raw_request: response.raw_request,
        raw_response: response.raw_response,
        provider_details: response.usage&.provider_details || {},
        status: "completed"
      )

      update!(status: "completed")
    end
  end

  # Records a failed generation
  def record_failure!(error)
    transaction do
      generations.create!(
        status: "failed",
        error_message: error.message
      )
      update!(status: "failed")
    end
  end

  # === Tool Call Methods ===

  # Records the start of a tool call
  #
  # @param name [String, Symbol] the tool name
  # @param arguments [Hash] the arguments passed to the tool
  # @param tool_call_id [String, nil] the LLM's tool call ID
  # @return [AgentToolCall] the created tool call record
  def record_tool_call_start(name:, arguments: {}, tool_call_id: nil)
    tool_calls.create!(
      name: name.to_s,
      arguments: arguments,
      tool_call_id: tool_call_id,
      status: "executing",
      started_at: Time.current
    )
  end

  # Records the completion of a tool call
  #
  # @param tool_call [AgentToolCall] the tool call record
  # @param result [Hash, Object] the result from the tool
  # @return [AgentToolCall] the updated tool call record
  def record_tool_call_complete(tool_call, result:)
    tool_call.complete!(result)
  end

  # Records a failed tool call
  #
  # @param tool_call [AgentToolCall] the tool call record
  # @param error [String, Exception] the error that occurred
  # @return [AgentToolCall] the updated tool call record
  def record_tool_call_failure(tool_call, error:)
    tool_call.fail!(error)
  end

  # Returns all tool calls for a specific tool
  #
  # @param name [String, Symbol] the tool name
  # @return [ActiveRecord::Relation<AgentToolCall>]
  def tool_calls_for(name)
    tool_calls.for_tool(name)
  end

  # Returns the results of all completed tool calls
  #
  # @return [Array<Hash>] array of tool results with metadata
  def tool_call_results
    tool_calls.completed.map do |tc|
      {
        name: tc.name,
        arguments: tc.parsed_arguments,
        result: tc.parsed_result,
        duration_ms: tc.duration_ms
      }
    end
  end

  # Returns the results of all completed tool calls for a specific tool
  #
  # @param name [String, Symbol] the tool name
  # @return [Array<Hash>] array of tool results
  def tool_results_for(name)
    tool_calls_for(name).completed.map(&:parsed_result)
  end

  # Returns statistics about tool calls in this context
  #
  # @return [Hash] tool call statistics
  def tool_call_statistics
    tool_calls.statistics
  end

  private

  def next_position
    (messages.maximum(:position) || -1) + 1
  end
end
