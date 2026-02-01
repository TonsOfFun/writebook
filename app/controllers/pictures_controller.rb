class PicturesController < ChapterablesController
  private
    def new_chapterable
      Picture.new chapterable_params
    end

    def chapterable_params
      params.fetch(:picture, {}).permit(:image, :caption)
    end
end
