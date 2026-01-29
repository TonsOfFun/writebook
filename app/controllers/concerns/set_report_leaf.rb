module SetBookLeaf
  extend ActiveSupport::Concern

  included do
    before_action :set_book
    before_action :set_leaf, :set_leafable, only: %i[ show edit update destroy ]
  end

  private
    def set_book
      @book = Book.accessable_or_published.find(params[:book_id])
    end

    def set_leaf
      @leaf = @book.leaves.active.find(params[:id])
    end

    def set_leafable
      instance_variable_set "@#{instance_name}", @leaf.leafable
    end

    def ensure_editable
      head :forbidden unless @book.editable?
    end

    def model_class
      controller_leafable_name.constantize
    end

    def instance_name
      controller_leafable_name.underscore
    end

    def controller_leafable_name
      self.class.to_s.remove("Controller").demodulize.singularize
    end
end
