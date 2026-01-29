class Reports::SourcesController < ApplicationController
  include ReportScoped

  before_action :ensure_editable
  before_action :set_source, only: %i[show edit update destroy]

  def index
    @sources = @report.sources.ordered
  end

  def show
  end

  def new
    @source = @report.sources.new
  end

  def create
    @source = @report.sources.new(source_params)

    if @source.save
      respond_to do |format|
        format.html { redirect_to report_sources_path(@report), notice: "Source added successfully" }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @source.update(source_params)
      redirect_to report_sources_path(@report), notice: "Source updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy

    respond_to do |format|
      format.html { redirect_to report_sources_path(@report), notice: "Source removed" }
      format.turbo_stream
    end
  end

  private

  def set_source
    @source = @report.sources.find(params[:id])
  end

  def source_params
    params.require(:source).permit(:name, :source_type, :url, :raw_content, :file)
  end
end
