class Reports::BookmarksController < ApplicationController
  allow_unauthenticated_access

  include ReportScoped

  def show
    @chapter = @report.chapters.active.find_by(id: last_read_chapter_id) if last_read_chapter_id.present?
  end

  private
    def last_read_chapter_id
      cookies["reading_progress_#{@report.id}"]
    end
end
