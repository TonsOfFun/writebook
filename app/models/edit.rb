class Edit < ApplicationRecord
  belongs_to :chapter
  delegated_type :chapterable, types: Chapterable::TYPES, dependent: :destroy

  enum :action, %w[ revision trash ].index_by(&:itself)

  scope :sorted, -> { order(created_at: :desc) }
  scope :before, ->(edit) { where("created_at < ?", edit.created_at) }
  scope :after, ->(edit) { where("created_at > ?", edit.created_at) }

  def previous
    chapter.edits.before(self).last
  end

  def next
    chapter.edits.after(self).first
  end
end
