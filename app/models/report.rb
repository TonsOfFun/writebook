class Report < ApplicationRecord
  include Accessable, Sluggable, SolidAgent::Contextable

  has_many :chapters, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_one_attached :cover, dependent: :purge_later

  scope :ordered, -> { order(:title) }
  scope :published, -> { where(published: true) }

  enum :theme, %w[ black blue green magenta orange violet white ].index_by(&:itself), suffix: true, default: :blue

  def press(chapterable, chapter_params)
    chapters.create! chapter_params.merge(chapterable: chapterable)
  end
end
