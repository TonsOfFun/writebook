class Section < ApplicationRecord
  include Leafable

  def searchable_content
    body
  end
end
