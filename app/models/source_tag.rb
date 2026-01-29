class SourceTag < ApplicationRecord
  belongs_to :source
  belongs_to :taggable, polymorphic: true

  validates :source_id, uniqueness: { scope: [:taggable_type, :taggable_id] }

  scope :ordered, -> { order(position: :asc) }

  # Delegate to get report through source
  delegate :report, to: :source

  def display_name
    source.display_name
  end

  def source_type
    source.source_type
  end

  def to_badge_html
    type_class = "source-tag--#{source.source_type}"
    <<~HTML.html_safe
      <span class="source-tag #{type_class}" title="#{source.display_name}">
        #{source_icon} #{source.display_name.truncate(20)}
      </span>
    HTML
  end

  private

  def source_icon
    case source.source_type
    when "pdf" then "\u{1F4C4}"   # page facing up
    when "image" then "\u{1F5BC}" # framed picture
    when "text" then "\u{1F4DD}"  # memo
    when "url" then "\u{1F517}"   # link
    end
  end
end
