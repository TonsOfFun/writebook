# ReferencesController provides endpoints for managing research references
# associated with pages and other leafable content.
#
# References are automatically extracted from ResearchAssistantAgent tool calls
# and can be displayed, copied, and used for citations.
class ReferencesController < ApplicationController
  before_action :set_leaf

  # GET /books/:book_id/leaves/:leaf_id/references
  # Returns references for a specific leaf (page, section, etc.)
  def index
    @references = @leaf.leafable.research_references.with_metadata

    respond_to do |format|
      format.html { render partial: "references/list", locals: { references: @references, leaf: @leaf } }
      format.json { render json: { references: @references.map(&:as_card) } }
    end
  end

  private

  def set_leaf
    @book = Book.find(params[:book_id])
    @leaf = @book.leaves.find(params[:leaf_id])
  end
end
