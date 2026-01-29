module SetReportChapter
  extend ActiveSupport::Concern

  included do
    before_action :set_report
    before_action :set_chapter, :set_chapterable, only: %i[ show edit update destroy ]
  end

  private
    def set_report
      @report = Report.accessable_or_published.find(params[:report_id])
    end

    def set_chapter
      @chapter = @report.chapters.active.find(params[:id])
    end

    def set_chapterable
      instance_variable_set "@#{instance_name}", @chapter.chapterable
    end

    def ensure_editable
      head :forbidden unless @report.editable?
    end

    def model_class
      controller_chapterable_name.constantize
    end

    def instance_name
      controller_chapterable_name.underscore
    end

    def controller_chapterable_name
      self.class.to_s.remove("Controller").demodulize.singularize
    end
end
