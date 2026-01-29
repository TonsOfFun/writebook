class ReportsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :ensure_index_is_not_empty, only: :index
  before_action :set_report, only: %i[ show edit update destroy ]
  before_action :set_users, only: %i[ new edit ]
  before_action :ensure_editable, only: %i[ edit update destroy ]

  def index
    @reports = Report.accessable_or_published.ordered
  end

  def new
    @report = Report.new
  end

  def create
    report = Report.create! report_params
    update_accesses(report)

    redirect_to report_slug_url(report)
  end

  def show
    @chapters = @report.chapters.active.with_chapterables.positioned
  end

  def edit
  end

  def update
    @report.update(report_params)
    update_accesses(@report)
    remove_cover if params[:remove_cover] == "true"

    redirect_to report_slug_url(@report)
  end

  def destroy
    @report.destroy

    redirect_to root_url
  end

  private
    def set_report
      @report = Report.accessable_or_published.find params[:id]
    end

    def set_users
      @users = User.active.ordered
    end

    def ensure_editable
      head :forbidden unless @report.editable?
    end

    def ensure_index_is_not_empty
      if !signed_in? && Report.published.none?
        require_authentication
      end
    end

    def report_params
      params.require(:report).permit(:title, :subtitle, :author, :cover, :remove_cover, :everyone_access, :theme)
    end

    def update_accesses(report)
      editors = [ Current.user.id, *params[:editor_ids]&.map(&:to_i) ]
      readers = [ Current.user.id, *params[:reader_ids]&.map(&:to_i) ]

      report.update_access(editors: editors, readers: readers)
    end

    def remove_cover
      @report.cover.purge
    end
end
