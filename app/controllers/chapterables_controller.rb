class ChapterablesController < ApplicationController
  allow_unauthenticated_access only: :show

  include SetReportChapter

  before_action :ensure_editable, except: :show
  before_action :broadcast_being_edited_indicator, only: :update

  def new
    @chapterable = new_chapterable
  end

  def create
    @chapter = @report.press new_chapterable, chapter_params
    position_new_chapter @chapter
  end

  def show
  end

  def edit
  end

  def update
    @chapter.edit chapterable_params: chapterable_params, chapter_params: chapter_params

    respond_to do |format|
      format.turbo_stream { render }
      format.html { head :no_content }
    end
  end

  def destroy
    @chapter.trashed!

    respond_to do |format|
      format.turbo_stream { render }
      format.html { redirect_to report_slug_url(@report) }
    end
  end

  private
    def chapter_params
      default_chapter_params.merge params.fetch(:chapter, {}).permit(:title)
    end

    def default_chapter_params
      { title: new_chapterable.model_name.human }
    end

    def new_chapterable
      raise NotImplementedError.new "Implement in subclass"
    end

    def chapterable_params
      raise NotImplementedError.new "Implement in subclass"
    end

    def position_new_chapter(chapter)
      if position = params[:position]&.to_i
        chapter.move_to_position position
      end
    end

    def broadcast_being_edited_indicator
      Turbo::StreamsChannel.broadcast_render_later_to @chapter, :being_edited,
        partial: "chapters/being_edited_by", locals: { chapter: @chapter, user: Current.user }
    end
end
