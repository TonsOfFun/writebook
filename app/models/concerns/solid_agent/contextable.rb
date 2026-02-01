# SolidAgent::Contextable provides agent context associations for models that can be
# used as contextable records for AI agent interactions.
#
# This allows any model to track its history of agent prompts, messages, and
# generation results through the polymorphic AgentContext association.
#
# @example Including in a model
#   class Page < ApplicationRecord
#     include SolidAgent::Contextable
#   end
#
# @example Accessing agent contexts
#   page.agent_contexts                    # All contexts for this page
#   page.agent_contexts.for_agent("WritingAssistantAgent")
#   page.agent_contexts.completed          # Only completed generations
#   page.latest_agent_context              # Most recent context
#
# @example Getting generation history
#   page.agent_generations                 # All generations across all contexts
#   page.total_tokens_used                 # Sum of all tokens used
#
module SolidAgent
  module Contextable
    extend ActiveSupport::Concern

    included do
      # All agent contexts associated with this record
      has_many :agent_contexts,
               as: :contextable,
               class_name: "AgentContext",
               dependent: :destroy

      # All agent generations through contexts (for analytics/history)
      has_many :agent_generations,
               through: :agent_contexts,
               source: :generations

      # All agent messages through contexts (for conversation history)
      has_many :agent_messages,
               through: :agent_contexts,
               source: :messages

      # All agent references through contexts (for citations/sources)
      has_many :agent_references,
               through: :agent_contexts,
               source: :references

      # All agent fragments through contexts (for content transformation history)
      has_many :agent_fragments,
               through: :agent_contexts,
               source: :fragments

      # Direct fragments associated with this contextable (for queries that bypass contexts)
      has_many :direct_agent_fragments,
               as: :contextable,
               class_name: "AgentFragment"
    end

    # Returns the most recent agent context for this record
    def latest_agent_context
      agent_contexts.order(created_at: :desc).first
    end

    # Returns contexts for a specific agent
    def contexts_for_agent(agent_name)
      agent_contexts.for_agent(agent_name)
    end

    # Returns the total tokens used across all agent interactions
    def total_tokens_used
      agent_generations.sum(:total_tokens)
    end

    # Returns generation stats for this record
    def agent_usage_stats
      {
        total_contexts: agent_contexts.count,
        completed_contexts: agent_contexts.completed.count,
        failed_contexts: agent_contexts.failed.count,
        total_generations: agent_generations.count,
        total_input_tokens: agent_generations.sum(:input_tokens),
        total_output_tokens: agent_generations.sum(:output_tokens),
        total_tokens: agent_generations.sum(:total_tokens)
      }
    end

    # Returns all research references for this record
    # Includes references from all research agent contexts
    def research_references
      agent_references
        .joins(:agent_context)
        .where(agent_contexts: { agent_name: "ResearchAssistantAgent" })
        .order(created_at: :desc)
    end

    # Returns reference cards for UI display
    def research_reference_cards
      research_references.with_metadata.map(&:as_card)
    end

    # Returns true if this record has any research references
    def has_research_references?
      research_references.exists?
    end

    # === Fragment Methods ===

    # Returns all fragments for this record, most recent first
    def content_fragments
      agent_fragments.recent
    end

    # Returns fragments with generated content (excludes pending/discarded)
    def generated_fragments
      agent_fragments.with_generations.active
    end

    # Returns applied fragments for version history display
    def applied_fragments
      agent_fragments.where(status: :applied).recent
    end

    # Returns true if this record has any content fragments
    def has_fragments?
      agent_fragments.exists?
    end

    # Returns fragment count for badge display
    def fragments_count
      agent_fragments.active.count
    end
  end
end
