class Chapter < ApplicationRecord
  include Editable, Positionable, Searchable, Contextable

  belongs_to :report, touch: true
  delegated_type :chapterable, types: Chapterable::TYPES, dependent: :destroy
  positioned_within :report, association: :chapters, filter: :active

  delegate :searchable_content, to: :chapterable

  enum :status, %w[ active trashed ].index_by(&:itself), default: :active

  scope :with_chapterables, -> { includes(:chapterable) }

  def slug
    title.parameterize.presence || "-"
  end
end
