class Reports::Chapters::MovesController < ApplicationController
  include ReportScoped

  before_action :ensure_editable

  def create
    chapter, *followed_by = chapters
    chapter.move_to_position(position, followed_by: followed_by)
  end

  private
    def position
      params[:position].to_i
    end

    def chapters
      @report.chapters.find(Array(params[:id]))
    end
end
