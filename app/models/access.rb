class Access < ApplicationRecord
  enum :level, %w[ reader editor ].index_by(&:itself)

  belongs_to :user
  belongs_to :book
end
