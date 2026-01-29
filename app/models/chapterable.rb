module Chapterable
  extend ActiveSupport::Concern

  TYPES = %w[ Page Section Picture Document ]

  included do
    include SolidAgent::Contextable

    has_one :chapter, as: :chapterable, inverse_of: :chapterable, touch: true
    has_one :report, through: :chapter

    delegate :title, to: :chapter
  end

  def searchable_content
    nil
  end

  class_methods do
    def chapterable_name
      @chapterable_name ||= ActiveModel::Name.new(self).singular.inquiry
    end
  end

  def chapterable_name
    self.class.chapterable_name
  end
end
