class PicturesController < LeafablesController
  private
    def new_leafable
      Picture.new leafable_params
    end

    def leafable_params
      params.fetch(:picture, {}).permit(:image, :caption)
    end
end
