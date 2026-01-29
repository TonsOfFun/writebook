class FindingsController < ChapterablesController
  private

  def default_chapter_params
    { title: "New Finding" }
  end

  def new_chapterable
    Finding.new chapterable_params
  end

  def chapterable_params
    params.fetch(:finding, {}).permit(:severity, :status, :category, :description, :recommendation, :evidence)
  end
end
