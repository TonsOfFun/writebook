require "test_helper"

class Books::BookmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "show includes a link to read the last read leaf" do
    cookies["reading_progress_#{books(:handbook).id}"] = "#{leaves(:welcome_page).id}/3"

    get book_bookmark_url(books(:handbook))

    assert_response :success
    assert_select "a", /Resume reading/
  end

  test "show includes a link to start reading if the last read leaf has been trashed" do
    leaves(:welcome_page).trashed!
    cookies["reading_progress_#{books(:handbook).id}"] = "#{leaves(:welcome_page).id}/3"

    get book_bookmark_url(books(:handbook))

    assert_response :success
    assert_select "a", /Start reading/
  end

  test "show includes a link to start reading if no reading progress has been recorded" do
    get book_bookmark_url(books(:handbook))

    assert_response :success
    assert_select "a", /Start reading/
  end
end
