class PagesController < ChapterablesController
  before_action :forget_reading_progress, except: :show

  private
    def forget_reading_progress
      cookies.delete "reading_progress_#{@report.id}"
    end

    def default_chapter_params
      { title: "Untitled" }
    end

    def new_chapterable
      Page.new chapterable_params
    end

    def chapterable_params
      params.fetch(:page, {}).permit(:body)
    end
end
