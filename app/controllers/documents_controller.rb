class DocumentsController < ChapterablesController
  private

  def new_chapterable
    Document.new chapterable_params
  end

  def chapterable_params
    params.fetch(:document, {}).permit(:file)
  end
end
