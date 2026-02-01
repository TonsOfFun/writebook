module Chapter::Editable
  extend ActiveSupport::Concern

  MINIMUM_TIME_BETWEEN_VERSIONS = 10.minutes

  included do
    has_many :edits, dependent: :delete_all

    after_update :record_moved_to_trash, if: :was_trashed?
  end

  def edit(chapterable_params: {}, chapter_params: {})
    if record_new_edit?(chapterable_params)
      update_and_record_edit chapter_params, chapterable_params
    else
      update_without_recording_edit chapter_params, chapterable_params
    end
  end

  private
    def record_new_edit?(chapterable_params)
      will_change_chapterable?(chapterable_params) && last_edit_old?
    end

    def last_edit_old?
      edits.empty? || edits.last.created_at.before?(MINIMUM_TIME_BETWEEN_VERSIONS.ago)
    end

    def will_change_chapterable?(chapterable_params)
      chapterable_params.select do |key, value|
        chapterable.attributes[key.to_s] != value
      end.present?
    end

    def update_without_recording_edit(chapter_params, chapterable_params)
      transaction do
        chapterable.update!(chapterable_params)

        edits.last&.touch
        update! chapter_params
      end
    end

    def update_and_record_edit(chapter_params, chapterable_params)
      transaction do
        new_chapterable = dup_chapterable_with_attachments chapterable
        new_chapterable.update!(chapterable_params)

        edits.revision.create!(chapterable: chapterable)
        update! chapter_params.merge(chapterable: new_chapterable)
      end
    end

    def dup_chapterable_with_attachments(chapterable)
      chapterable.dup.tap do |new|
        chapterable.attachment_reflections.each do |name, _|
          new.send(name).attach(chapterable.send(name).blob)
        end
      end
    end

    def record_moved_to_trash
      edits.trash.create!(chapterable: chapterable)
    end

    def was_trashed?
      trashed? && previous_changes.include?(:status)
    end
end
