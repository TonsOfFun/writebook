require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "document is a valid leafable type" do
    assert_includes Leafable::TYPES, "Document"
  end

  test "document responds to searchable_content" do
    doc = Document.new
    assert_respond_to doc, :searchable_content
  end

  test "document responds to file attachment" do
    doc = Document.new
    assert_respond_to doc, :file
  end

  test "document has processing status" do
    doc = Document.new
    assert_equal "pending", doc.processing_status
  end

  test "document stores page text as JSON" do
    doc = Document.new(page_text: { "1" => "Page one content", "2" => "Page two content" })
    assert_equal "Page one content", doc.text_for_page(1)
    assert_equal "Page two content", doc.text_for_page(2)
  end

  test "searchable_content joins all page text" do
    doc = Document.new(page_text: { "1" => "First page", "2" => "Second page" })
    assert_includes doc.searchable_content, "First page"
    assert_includes doc.searchable_content, "Second page"
  end

  test "text_for_pages returns range of pages" do
    doc = Document.new(page_text: { "1" => "One", "2" => "Two", "3" => "Three" })
    result = doc.text_for_pages(1..2)
    assert_includes result, "One"
    assert_includes result, "Two"
    refute_includes result, "Three"
  end
end
