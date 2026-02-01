class Finding < ApplicationRecord
  include Chapterable
  include Taggable
  include Suggestable

  SEVERITIES = %w[critical high medium low info].freeze
  STATUSES = %w[open confirmed resolved wont_fix].freeze
  CATEGORIES = %w[security performance architecture code_quality compliance other].freeze

  validates :severity, presence: true, inclusion: { in: SEVERITIES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

  scope :by_severity, -> { order(Arel.sql("CASE severity WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 WHEN 'low' THEN 3 WHEN 'info' THEN 4 END")) }
  scope :open_findings, -> { where(status: %w[open confirmed]) }
  scope :resolved_findings, -> { where(status: %w[resolved wont_fix]) }

  def searchable_content
    [description, recommendation, evidence].compact.join("\n\n")
  end

  def severity_color
    case severity
    when "critical" then "red"
    when "high" then "orange"
    when "medium" then "yellow"
    when "low" then "blue"
    when "info" then "gray"
    end
  end

  def severity_emoji
    case severity
    when "critical" then "\u{1F534}"  # red circle
    when "high" then "\u{1F7E0}"      # orange circle
    when "medium" then "\u{1F7E1}"    # yellow circle
    when "low" then "\u{1F535}"       # blue circle
    when "info" then "\u{26AA}"       # white circle
    end
  end

  def status_label
    case status
    when "open" then "Open"
    when "confirmed" then "Confirmed"
    when "resolved" then "Resolved"
    when "wont_fix" then "Won't Fix"
    end
  end

  def critical?
    severity == "critical"
  end

  def high?
    severity == "high"
  end

  def resolved?
    status.in?(%w[resolved wont_fix])
  end
end
