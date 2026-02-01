module Report::Sluggable
  extend ActiveSupport::Concern

  included do
    before_save :generate_slug, if: -> { slug.blank? }
  end

  def generate_slug
    self.slug = title.parameterize
  end
end
