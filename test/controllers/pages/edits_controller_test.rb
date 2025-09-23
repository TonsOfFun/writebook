require "test_helper"

class Pages::EditsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "show an edit" do
    leaves(:welcome_page).edit leafable_params: { body: "Completely new content" }

    get page_edit_url(leaves(:welcome_page), leaves(:welcome_page).edits.last)

    assert_response :success
    assert_select "p", /such a great handbook/
    assert_select "p", /Completely new content/
  end

  test "show latest edit" do
    leaves(:welcome_page).edit leafable_params: { body: "Updated" }

    get page_edit_url(leaves(:welcome_page), "latest")

    assert_response :success
    assert_select "p", /such a great handbook/
  end
end
