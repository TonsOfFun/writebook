require "test_helper"

class Leaf::SearchableTest < ActiveSupport::TestCase
  setup do
    Leaf.reindex_all
  end

  test "leaf body is indexed and searchable" do
    leaves = Leaf.search("great handbook")
    assert_includes leaves, leaves(:welcome_page)
  end

  test "updating a leaf updates the search index" do
    pages(:welcome).update! body: "sausages"

    leaves = Leaf.search("sausages")
    assert_includes leaves, leaves(:welcome_page)
  end

  test "search includes highlighted matches" do
    leaves = Leaf.search("great handbook")
    assert_includes leaves.first.title_match, "The <mark>Handbook</mark>"
    assert_includes leaves.first.content_match, "<mark>great</mark> <mark>handbook</mark>"
  end

  test "leaves with no searchable content are not indexed" do
    leaves = Leaf.search("welcome")
    assert_not_includes leaves, leaves(:welcome_section)
  end

  test "matches_for_highlight returns the matching terms, longest first" do
    matches = leaves(:welcome_page).matches_for_highlight("great handbook")
    assert_equal [ "handbook", "great" ], matches
  end

  test "matches_for_highlight is empty when there is no match" do
    markup = leaves(:welcome_page).matches_for_highlight("haggis")
    assert_empty markup
  end
end
