module BookScoped extend ActiveSupport::Concern
  included do
    before_action :set_book
  end

  private
    def set_book
      @book = Book.accessable_or_published.find(params[:book_id])
    end

    def ensure_editable
      head :forbidden unless @book.editable?
    end
end
