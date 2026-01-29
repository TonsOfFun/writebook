module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :source_tags, as: :taggable, dependent: :destroy
    has_many :sources, through: :source_tags
  end

  def tag_source(source, context: nil, excerpt: nil)
    source_tags.find_or_create_by!(source: source) do |tag|
      tag.context = context
      tag.excerpt = excerpt
      tag.position = source_tags.maximum(:position).to_i + 1
    end
  end

  def untag_source(source)
    source_tags.find_by(source: source)&.destroy
  end

  def tagged_with?(source)
    source_tags.exists?(source: source)
  end

  def source_tags_for_display
    source_tags.includes(:source).ordered
  end
end
