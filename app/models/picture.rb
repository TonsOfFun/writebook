class Picture < ApplicationRecord
  include Chapterable

  has_one_attached :image do |attachable|
    attachable.variant :large, resize_to_limit: [ 1500, 1500 ]
  end
end
