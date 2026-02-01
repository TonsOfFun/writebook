class Reports::PublicationsController < ApplicationController
  include ReportScoped

  before_action :ensure_editable, only: %i[ edit update ]

  def show
  end

  def edit
  end

  def update
    @report.update! report_params
    redirect_to report_slug_url(@report)
  end

  private
    def report_params
      params.require(:report).permit(:published, :slug)
    end
end
