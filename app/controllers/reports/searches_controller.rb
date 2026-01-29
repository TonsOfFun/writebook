class Reports::SearchesController < ApplicationController
  allow_unauthenticated_access

  include ReportScoped

  def create
    @chapters = @report.chapters.active.search(params[:search]).favoring_title.limit(50)
  end
end
