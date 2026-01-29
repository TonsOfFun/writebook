class Books::SearchesController < ApplicationController
  allow_unauthenticated_access

  include BookScoped

  def create
    @leaves = @book.leaves.active.search(params[:search]).favoring_title.limit(50)
  end
end
