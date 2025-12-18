require "test_helper"

class ContextRetrievalServiceTest < ActiveSupport::TestCase
  test "extracts key terms from text" do
    service = ContextRetrievalService.new(leaves(:welcome_page))

    terms = service.send(:extract_key_terms, "The quick brown fox jumps over the lazy dog")
    assert_includes terms, "quick"
    assert_includes terms, "brown"
    assert_includes terms, "jumps"
    refute_includes terms, "the"  # stop word
    refute_includes terms, "over"  # stop word
  end

  test "builds FTS query from terms" do
    service = ContextRetrievalService.new(leaves(:welcome_page))

    query = service.send(:build_fts_query, %w[quick brown fox])
    assert_equal '"quick" OR "brown" OR "fox"', query
  end

  test "returns empty array when query is blank" do
    leaf = leaves(:welcome_page)
    service = ContextRetrievalService.new(leaf, query: "")

    result = service.retrieve
    assert_equal [], result
  end

  test "retrieve_with_context returns structured data" do
    leaf = leaves(:welcome_page)
    service = ContextRetrievalService.new(leaf)

    result = service.retrieve_with_context(limit: 2)

    if result.any?
      first = result.first
      assert first.key?(:id)
      assert first.key?(:title)
      assert first.key?(:type)
      assert first.key?(:content)
    end
  end

  test "does not include current leaf in results" do
    leaf = leaves(:welcome_page)
    service = ContextRetrievalService.new(leaf)

    result = service.retrieve(limit: 10)

    refute result.map(&:id).include?(leaf.id)
  end
end
