class Books::BookmarksController < ApplicationController
  allow_unauthenticated_access

  include BookScoped

  def show
    @leaf = @book.leaves.active.find_by(id: last_read_leaf_id) if last_read_leaf_id.present?
  end

  private
    def last_read_leaf_id
      cookies["reading_progress_#{@book.id}"]
    end
end
