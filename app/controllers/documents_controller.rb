class DocumentsController < LeafablesController
  private

  def new_leafable
    Document.new leafable_params
  end

  def leafable_params
    params.fetch(:document, {}).permit(:file)
  end
end
