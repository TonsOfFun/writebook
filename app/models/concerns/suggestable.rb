module Suggestable
  extend ActiveSupport::Concern

  included do
    has_many :suggestions, as: :suggestable, dependent: :destroy
  end

  def pending_suggestions
    suggestions.pending.ordered
  end

  def pending_suggestions_count
    suggestions.pending.count
  end

  def has_pending_suggestions?
    suggestions.pending.exists?
  end

  def create_suggestion(type:, original_text: nil, suggested_text: nil, comment: nil, author: nil, ai_generated: false, start_offset: nil, end_offset: nil)
    suggestions.create!(
      suggestion_type: type,
      original_text: original_text,
      suggested_text: suggested_text,
      comment: comment,
      author: author,
      ai_generated: ai_generated,
      start_offset: start_offset,
      end_offset: end_offset
    )
  end

  def apply_suggestion(suggestion)
    return false unless suggestion.pending? && suggestion.edit?
    return false unless suggestion.suggestable == self

    # This is a placeholder - actual implementation depends on the content model
    # Override in including class for specific behavior
    suggestion.accept!
    true
  end
end
