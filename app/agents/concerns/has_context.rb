# HasContext provides database-backed prompt context management for agents.
#
# This concern adds the `has_context` class method which configures an agent
# to persist its prompt context, messages, and generation results to the database.
#
# @example Basic usage in an agent
#   class WritingAssistantAgent < ApplicationAgent
#     has_context
#
#     def improve
#       prompt "Please improve the following text:", message: params[:content]
#     end
#   end
#
# @example With custom model classes
#   class WritingAssistantAgent < ApplicationAgent
#     has_context context_class: "Conversation",
#                 message_class: "ConversationMessage",
#                 generation_class: "ConversationGeneration"
#   end
#
# @example Using context in an agent action
#   class ChatAgent < ApplicationAgent
#     has_context
#
#     def chat
#       # Load or create context
#       load_context(contextable: params[:user])
#
#       # Add the user's message
#       context.add_user_message(params[:message])
#
#       # Set up the prompt with context history
#       prompt messages: context.messages.map(&:to_message_hash)
#     end
#
#     after_generation :save_response
#
#     private
#
#     def save_response
#       context.record_generation!(response) if response&.success?
#     end
#   end
#
module HasContext
  extend ActiveSupport::Concern

  included do
    # Class-level configuration for context persistence
    class_attribute :context_config, default: {}

    # Instance-level context accessor
    attr_accessor :context
  end

  class_methods do
    # Configures database-backed context persistence for this agent.
    #
    # @param context_class [String, Class] The model class for storing context (default: "AgentContext")
    # @param message_class [String, Class] The model class for storing messages (default: "AgentMessage")
    # @param generation_class [String, Class] The model class for storing generations (default: "AgentGeneration")
    # @param auto_save [Boolean] Automatically save generation results (default: true)
    #
    # @example Basic configuration
    #   has_context
    #
    # @example Custom model classes
    #   has_context context_class: "Conversation",
    #               message_class: "ConversationMessage",
    #               generation_class: "ConversationGeneration"
    #
    # @example Disable auto-save
    #   has_context auto_save: false
    #
    def has_context(context_class: "AgentContext",
                    message_class: "AgentMessage",
                    generation_class: "AgentGeneration",
                    auto_save: true)
      self.context_config = {
        context_class: context_class,
        message_class: message_class,
        generation_class: generation_class,
        auto_save: auto_save
      }

      # Add callback to save generation results if auto_save is enabled
      if auto_save
        after_generation :persist_generation_to_context
      end
    end
  end

  # Returns the configured context model class
  def context_class
    @context_class ||= context_config[:context_class].to_s.constantize
  end

  # Returns the configured message model class
  def message_class
    @message_class ||= context_config[:message_class].to_s.constantize
  end

  # Returns the configured generation model class
  def generation_class
    @generation_class ||= context_config[:generation_class].to_s.constantize
  end

  # Loads or creates a context for this agent.
  #
  # @param contextable [ActiveRecord::Base, nil] Optional record to associate context with
  # @param context_id [Integer, nil] Optional existing context ID to load
  # @param options [Hash] Additional options to merge into context
  # @return [AgentContext] The loaded or created context
  #
  # @example Load context for a specific record
  #   load_context(contextable: current_user)
  #
  # @example Load existing context by ID
  #   load_context(context_id: params[:context_id])
  #
  # @example Create new context with options
  #   load_context(options: { model: "gpt-4" })
  #
  def load_context(contextable: nil, context_id: nil, **options)
    @context = if context_id
      context_class.find(context_id)
    elsif contextable
      context_class.find_or_create_by!(
        contextable: contextable,
        agent_name: self.class.name,
        action_name: action_name
      ) do |ctx|
        ctx.instructions = prompt_options[:instructions]
        ctx.options = options
        ctx.trace_id = prompt_options[:trace_id]
      end
    else
      context_class.create!(
        agent_name: self.class.name,
        action_name: action_name,
        instructions: prompt_options[:instructions],
        options: options,
        trace_id: prompt_options[:trace_id]
      )
    end
  end

  # Creates a new context (always creates, never finds existing)
  #
  # @param contextable [ActiveRecord::Base, nil] Optional record to associate context with
  # @param options [Hash] Additional options to merge into context
  # @return [AgentContext] The created context
  #
  def create_context(contextable: nil, **options)
    @context = context_class.create!(
      contextable: contextable,
      agent_name: self.class.name,
      action_name: action_name,
      instructions: prompt_options[:instructions],
      options: options,
      trace_id: prompt_options[:trace_id]
    )
  end

  # Adds a message to the current context
  #
  # @param role [String] Message role (user, assistant, system, tool)
  # @param content [String] Message content
  # @param attributes [Hash] Additional message attributes
  # @return [AgentMessage] The created message
  #
  def add_message(role:, content:, **attributes)
    ensure_context!
    context.messages.create!(role: role, content: content, **attributes)
  end

  # Convenience method to add a user message
  def add_user_message(content, **attributes)
    add_message(role: "user", content: content, **attributes)
  end

  # Convenience method to add an assistant message
  def add_assistant_message(content, **attributes)
    add_message(role: "assistant", content: content, **attributes)
  end

  # Returns messages from context formatted for prompt
  #
  # @return [Array<Hash>] Messages formatted for ActiveAgent prompt
  #
  def context_messages
    return [] unless context
    context.messages.map(&:to_message_hash)
  end

  # Sets up the prompt with context messages
  #
  # This is a convenience method that loads context messages into the prompt.
  # Call this in your agent action to include conversation history.
  #
  # @example
  #   def chat
  #     load_context(contextable: params[:user])
  #     with_context_messages
  #     prompt params[:message]
  #   end
  #
  def with_context_messages
    prompt messages: context_messages if context_messages.any?
  end

  private

  # Callback to persist generation results to context
  def persist_generation_to_context
    return unless context && response&.success?

    begin
      context.record_generation!(response)
    rescue => e
      Rails.logger.error "[HasContext] Failed to persist generation: #{e.message}"
    end
  end

  # Ensures a context exists, raising an error if not
  def ensure_context!
    raise "No context loaded. Call load_context or create_context first." unless context
  end
end
