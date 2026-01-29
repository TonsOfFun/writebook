class Section < ApplicationRecord
  include Chapterable

  def searchable_content
    body
  end
end
