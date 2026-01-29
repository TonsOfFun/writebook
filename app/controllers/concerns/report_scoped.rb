module ReportScoped extend ActiveSupport::Concern
  included do
    before_action :set_report
  end

  private
    def set_report
      @report = Report.accessable_or_published.find(params[:report_id])
    end

    def ensure_editable
      head :forbidden unless @report.editable?
    end
end
