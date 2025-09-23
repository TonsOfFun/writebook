require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @join_code = accounts(:signal).join_code
  end

  test "new" do
    get join_url(@join_code)
    assert_response :success
  end

  test "new does not allow a signed in user" do
    sign_in :david

    get join_url(@join_code)
    assert_redirected_to root_url
  end

  test "new requires a join code" do
    get join_url("not")
    assert_response :not_found
  end

  test "create" do
    assert_difference -> { User.count }, 1 do
      post join_url(@join_code), params: { user: { name: "New Person", email_address: "new@37signals.com", password: "secret123456" } }
    end

    assert_redirected_to root_url

    user = User.last
    assert_equal user.id, Session.find_by(token: parsed_cookies.signed[:session_token]).user.id
  end

  test "creating a new user with an existing email address redirects to login screen" do
    assert_no_difference -> { User.count } do
      post join_url(@join_code), params: { user: { name: "Another David", email_address: users(:david).email_address, password: "secret123456" } }
    end

    assert_redirected_to new_session_url(email_address: users(:david).email_address)
  end

  test "update" do
    sign_in :david
    assert users(:david).administrator?

    put user_url(users(:kevin)), params: { user: { role: "administrator" } }

    assert_redirected_to users_url
    assert users(:kevin).reload.administrator?
  end

  test "update does not allow non-admins to change roles" do
    sign_in :kevin
    assert_not users(:kevin).administrator?

    put user_url(users(:kevin)), params: { user: { role: "administrator" } }

    assert_response :forbidden
    assert_not users(:kevin).reload.administrator?
  end

  test "destroy" do
    sign_in :david

    assert_difference -> { User.active.count }, -1 do
      delete user_url(users(:kevin))
    end

    assert_redirected_to users_url
    assert_nil User.active.find_by(id: users(:kevin).id)
  end

  test "destroy is not allowed to non-admins" do
    sign_in :kevin

    delete user_url(users(:david))
    assert_response :forbidden
  end
end
