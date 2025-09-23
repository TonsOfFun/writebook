require "test_helper"

class Users::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "show" do
    sign_in :david

    get user_profile_url(users(:david))
    assert_response :success

    get user_profile_url(users(:kevin))
    assert_response :success
  end

  test "edit is accessable to the current user" do
    sign_in :david

    get edit_user_profile_url(users(:david))
    assert_response :success

    get edit_user_profile_url(users(:kevin))
    assert_response :forbidden
  end

  test "update modifies profile for current user" do
    sign_in :kevin

    put user_profile_url(users(:kevin)), params: { user: { name: "Bob" } }

    assert_redirected_to users_url
    assert_equal "Bob", users(:kevin).reload.name
  end

  test "update prohibits modifying profile of other users" do
    sign_in :david

    put user_profile_url(users(:kevin)), params: { user: { name: "Bob" } }

    assert_response :forbidden
    assert_equal "Kevin", users(:kevin).reload.name
  end
end
