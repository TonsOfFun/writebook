require "test_helper"

class Books::SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin

    Leaf.reindex_all
  end

  test "create finds matching pages" do
    post book_search_url(books(:handbook)), params: { search: "Thanks" }

    assert_response :success
    assert_select "a", text: /Thanks for reading/i
  end

  test "create allows searching published books without being logged in" do
    sign_out
    books(:handbook).update!(published: true)

    post book_search_url(books(:handbook)), params: { search: "Thanks" }
    assert_response :success

    books(:handbook).update!(published: false)

    post book_search_url(books(:handbook)), params: { search: "Thanks" }
    assert_response :not_found
  end

  test "create shows when there are no matches" do
    post book_search_url(books(:handbook)), params: { search: "the invisible man" }

    assert_response :success
    assert_select "p", text: /no matches/i
  end

  test "create shows no matches when the search has only ignored characters" do
    post book_search_url(books(:handbook)), params: { search: "^$" }

    assert_response :success
    assert_select "p", text: /no matches/i
  end

  test "create does not find trashed pages" do
    leaves(:summary_page).trashed!

    post book_search_url(books(:handbook)), params: { search: "Thanks" }

    assert_response :success
    assert_select "p", text: /no matches/i
  end
end
