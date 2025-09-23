class SectionsController < LeafablesController
  private
    def new_leafable
      Section.new leafable_params
    end

    def leafable_params
      params.fetch(:section, {}).permit(:body, :theme)
        .with_defaults(body: default_body)
    end

    def default_body
      params.fetch(:leaf, {})[:title]
    end
end
