# AgentToolCall records individual tool executions within an agent context.
#
# This model captures the complete lifecycle of a tool call including:
# - The tool name and arguments requested by the LLM
# - The result returned by the tool method
# - Execution timing and status
#
# @example Recording a tool call
#   context.tool_calls.create!(
#     name: "navigate",
#     tool_call_id: "call_abc123",
#     arguments: { url: "https://example.com" },
#     status: "pending"
#   )
#
# @example Finding all navigation tool calls
#   context.tool_calls.for_tool(:navigate)
#
# @example Calculating total tool execution time
#   context.tool_calls.total_duration_ms
#
class AgentToolCall < ApplicationRecord
  # Associations
  belongs_to :agent_context

  # Validations
  validates :name, presence: true
  validates :status, inclusion: { in: %w[pending executing completed failed] }

  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :pending, -> { where(status: "pending") }
  scope :executing, -> { where(status: "executing") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :for_tool, ->(name) { where(name: name.to_s) }
  scope :successful, -> { completed.where(error_message: nil) }

  # Callbacks
  before_create :set_position

  # Marks the tool call as started
  #
  # @return [self]
  def start!
    update!(
      status: "executing",
      started_at: Time.current
    )
    self
  end

  # Marks the tool call as completed with the given result
  #
  # @param result [Hash, Object] the result returned by the tool
  # @return [self]
  def complete!(result)
    now = Time.current
    duration = started_at ? ((now - started_at) * 1000).to_i : nil

    update!(
      status: "completed",
      result: result,
      completed_at: now,
      duration_ms: duration
    )
    self
  end

  # Marks the tool call as failed with an error message
  #
  # @param error [String, Exception] the error that occurred
  # @return [self]
  def fail!(error)
    now = Time.current
    duration = started_at ? ((now - started_at) * 1000).to_i : nil
    error_msg = error.is_a?(Exception) ? error.message : error.to_s

    update!(
      status: "failed",
      error_message: error_msg,
      completed_at: now,
      duration_ms: duration
    )
    self
  end

  # Returns whether the tool call was successful
  #
  # @return [Boolean]
  def success?
    status == "completed" && error_message.nil?
  end

  # Returns whether the tool call failed
  #
  # @return [Boolean]
  def failed?
    status == "failed"
  end

  # Returns whether the tool call is still in progress
  #
  # @return [Boolean]
  def in_progress?
    status.in?(%w[pending executing])
  end

  # Returns the result as a hash with symbolized keys
  #
  # @return [Hash, nil]
  def parsed_result
    return nil unless result

    case result
    when Hash
      result.deep_symbolize_keys
    when String
      begin
        JSON.parse(result, symbolize_names: true)
      rescue JSON::ParserError
        { raw: result }
      end
    else
      result
    end
  end

  # Returns the arguments as a hash with symbolized keys
  #
  # @return [Hash]
  def parsed_arguments
    return {} unless arguments

    case arguments
    when Hash
      arguments.deep_symbolize_keys
    when String
      begin
        JSON.parse(arguments, symbolize_names: true)
      rescue JSON::ParserError
        {}
      end
    else
      {}
    end
  end

  # Class method to calculate total duration of tool calls
  #
  # @return [Integer] total duration in milliseconds
  def self.total_duration_ms
    sum(:duration_ms) || 0
  end

  # Class method to get a summary of tool call statistics
  #
  # @return [Hash] statistics about tool calls
  def self.statistics
    {
      total: count,
      completed: completed.count,
      failed: failed.count,
      pending: pending.count,
      executing: executing.count,
      total_duration_ms: total_duration_ms,
      by_tool: group(:name).count
    }
  end

  private

  def set_position
    return if position_changed? && position.present?

    # Use a direct query to avoid association cache issues
    max_position = AgentToolCall.where(agent_context_id: agent_context_id).maximum(:position)
    self.position = (max_position || -1) + 1
  end
end
