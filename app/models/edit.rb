class Edit < ApplicationRecord
  belongs_to :leaf
  delegated_type :leafable, types: Leafable::TYPES, dependent: :destroy

  enum :action, %w[ revision trash ].index_by(&:itself)

  scope :sorted, -> { order(created_at: :desc) }
  scope :before, ->(edit) { where("created_at < ?", edit.created_at) }
  scope :after, ->(edit) { where("created_at > ?", edit.created_at) }

  def previous
    leaf.edits.before(self).last
  end

  def next
    leaf.edits.after(self).first
  end
end
