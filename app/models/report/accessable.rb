module Report::Accessable
  extend ActiveSupport::Concern

  included do
    has_many :accesses, dependent: :destroy
    scope :with_everyone_access, -> { where(everyone_access: true) }
  end

  class_methods do
    def accessable_or_published(user: Current.user)
      if user.present?
        accessable_or_published_reports
      else
        published
      end
    end

    def accessable_or_published_reports(user: Current.user)
      user.reports.or(published).distinct
    end
  end

  def accessable?(user: Current.user)
    accesses.exists?(user: user)
  end

  def editable?(user: Current.user)
    access_for(user: user)&.editor? || user&.administrator?
  end

  def access_for(user: Current.user)
    accesses.find_by(user: user)
  end

  def update_access(editors:, readers:)
    editors = Set.new(editors)
    readers = Set.new(everyone_access? ? User.active.ids : readers)

    all = editors + readers
    all_accesses = all.collect { |user_id|
      { user_id: user_id, level: editors.include?(user_id) ? :editor : :reader }
    }

    accesses.upsert_all(all_accesses, unique_by: [ :report_id, :user_id ])
    accesses.where.not(user_id: all).delete_all
  end
end
