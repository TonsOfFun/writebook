class Suggestion < ApplicationRecord
  SUGGESTION_TYPES = %w[edit add delete comment].freeze
  STATUSES = %w[pending accepted rejected resolved].freeze

  belongs_to :suggestable, polymorphic: true
  belongs_to :author, class_name: "User", optional: true
  belongs_to :resolved_by, class_name: "User", optional: true

  validates :suggestion_type, presence: true, inclusion: { in: SUGGESTION_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :suggested_text, presence: true, unless: -> { suggestion_type == "delete" || suggestion_type == "comment" }

  scope :ordered, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: "pending") }
  scope :resolved, -> { where.not(status: "pending") }
  scope :ai_generated, -> { where(ai_generated: true) }
  scope :human_authored, -> { where(ai_generated: false) }

  before_save :compute_content_hash, if: -> { start_offset.present? && end_offset.present? }

  def accept!(user = nil)
    update!(
      status: "accepted",
      resolved_by: user,
      resolved_at: Time.current
    )
  end

  def reject!(user = nil)
    update!(
      status: "rejected",
      resolved_by: user,
      resolved_at: Time.current
    )
  end

  def resolve!(user = nil)
    update!(
      status: "resolved",
      resolved_by: user,
      resolved_at: Time.current
    )
  end

  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def rejected?
    status == "rejected"
  end

  def edit?
    suggestion_type == "edit"
  end

  def add?
    suggestion_type == "add"
  end

  def delete?
    suggestion_type == "delete"
  end

  def comment?
    suggestion_type == "comment"
  end

  def author_name
    if ai_generated?
      "AI Assistant"
    elsif author.present?
      author.name
    else
      "Anonymous"
    end
  end

  def diff_preview
    return comment if comment?
    return "Delete: #{original_text.truncate(50)}" if delete?
    return "Add: #{suggested_text.truncate(50)}" if add?

    "Change: #{original_text.truncate(25)} \u2192 #{suggested_text.truncate(25)}"
  end

  private

  def compute_content_hash
    # Create a hash based on position and surrounding context
    # This helps anchor suggestions even if content shifts slightly
    self.content_hash = Digest::SHA256.hexdigest("#{start_offset}:#{end_offset}:#{original_text&.first(100)}")
  end
end
