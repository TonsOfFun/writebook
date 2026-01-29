class SectionsController < ChapterablesController
  private
    def new_chapterable
      Section.new chapterable_params
    end

    def chapterable_params
      params.fetch(:section, {}).permit(:body, :theme)
        .with_defaults(body: default_body)
    end

    def default_body
      params.fetch(:chapter, {})[:title]
    end
end
