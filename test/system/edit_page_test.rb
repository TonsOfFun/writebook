require "application_system_test_case"

class EditPageTest < ApplicationSystemTestCase
  setup do
    sign_in "kevin@37signals.com"
  end

  test "edit page" do
    visit edit_book_page_url(books(:handbook), leaves(:welcome_page))
    assert_selector "house-md"

    fill_house_editor "page[body]", with: "Welcome to the handbook! This is the **first** page."

    click_button "Save"

    assert_selector ".house-md-content", text: "Welcome to the handbook! This is the **first** page."
    assert_selector ".house-md-content strong", text: "first"
  end
end
